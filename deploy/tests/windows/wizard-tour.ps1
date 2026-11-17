#Requires -Version 5.1
<#
.SYNOPSIS
  Clicks through the KadaiSetup.exe wizard like a customer and saves a PNG of every page.

.DESCRIPTION
  Visual review of the installer on a throw-away Windows machine (CI runner): the pictures are
  uploaded as a workflow artifact, so layout problems (cut-off text, Tamil not fitting, a page
  that looks wrong) are seen before a shop sees them.

    -Lang ask       shows the language dialog first (then continues in its default language)
    -Lang tamil     starts directly in Tamil (english likewise)
    -Install        goes on after the "Ready" page: progress pages, then the finish page
                    (without it the tour stops at "Ready" and closes Setup; nothing is installed)
    -BusyPort 8080  keeps that port occupied until Setup has shown its "port in use" message

  Windows are driven with posted button clicks (no keyboard focus needed) and captured with
  PrintWindow, so the tour also works when the window is not in front.
  Never run with -Install on a real shop PC.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Setup,
  [string]$OutDir = 'dist\wizard-tour',
  [ValidateSet('ask', 'english', 'tamil')][string]$Lang = 'ask',
  [string]$Prefix,
  [switch]$Install,
  [int]$BusyPort = 0,
  [int]$InstallTimeoutSeconds = 1500
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Text;

public static class KadaiTourWin {
  public delegate bool EnumProc(IntPtr hwnd, IntPtr lparam);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc cb, IntPtr lparam);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr parent, EnumProc cb, IntPtr lparam);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr hwnd, StringBuilder s, int max);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr hwnd, uint msg, IntPtr wparam, StringBuilder lparam);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr wparam, IntPtr lparam);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
  [DllImport("user32.dll")] public static extern bool IsWindowEnabled(IntPtr hwnd);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
  [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
  [DllImport("user32.dll")] static extern bool PrintWindow(IntPtr hwnd, IntPtr hdc, uint flags);

  public static List<IntPtr> TopLevel() {
    var list = new List<IntPtr>();
    EnumWindows((h, l) => { list.Add(h); return true; }, IntPtr.Zero);
    return list;
  }
  public static List<IntPtr> Children(IntPtr parent) {
    var list = new List<IntPtr>();
    EnumChildWindows(parent, (h, l) => { list.Add(h); return true; }, IntPtr.Zero);
    return list;
  }
  public static string ClassOf(IntPtr hwnd) {
    var s = new StringBuilder(256);
    GetClassName(hwnd, s, s.Capacity);
    return s.ToString();
  }
  // WM_GETTEXT also reads controls of another process (GetWindowText does not).
  public static string TextOf(IntPtr hwnd) {
    var s = new StringBuilder(1024);
    SendMessage(hwnd, 0x000D, (IntPtr)s.Capacity, s);
    return s.ToString();
  }
  public static int ProcessOf(IntPtr hwnd) {
    uint pid;
    GetWindowThreadProcessId(hwnd, out pid);
    return (int)pid;
  }
  public static Bitmap Capture(IntPtr hwnd) {
    RECT r;
    GetWindowRect(hwnd, out r);
    int w = Math.Max(1, r.Right - r.Left), h = Math.Max(1, r.Bottom - r.Top);
    var bmp = new Bitmap(w, h);
    using (var g = Graphics.FromImage(bmp)) {
      IntPtr dc = g.GetHdc();
      try { PrintWindow(hwnd, dc, 2); } finally { g.ReleaseHdc(dc); }
    }
    return bmp;
  }
  public static void Click(IntPtr button) { PostMessage(button, 0x00F5, IntPtr.Zero, IntPtr.Zero); }  // BM_CLICK
  public static int[] RectOf(IntPtr hwnd) {
    RECT r;
    GetWindowRect(hwnd, out r);
    return new int[] { r.Left, r.Top, r.Right, r.Bottom };
  }
}
'@

$Setup = (Resolve-Path -LiteralPath $Setup).Path
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path -LiteralPath $OutDir).Path
if (-not $Prefix) { $Prefix = $Lang }
$script:Shot = 0

# Button captions without the "&" accelerator mark, English and Tamil.
$InstallNames = @('Install', 'நிறுவு')   # caption of Next on the Ready page
$FinishNames = @('Finish', 'முடி')
$OkNames = @('OK', 'சரி', 'Yes', 'ஆம்')

function Write-Step([string]$Message) { Write-Host "[wizard-tour] $Message" -ForegroundColor Cyan }

function Get-SetupWindow([string]$ClassName) {
  foreach ($h in [KadaiTourWin]::TopLevel()) {
    if (-not [KadaiTourWin]::IsWindowVisible($h)) { continue }
    if ([KadaiTourWin]::ClassOf($h) -ne $ClassName) { continue }
    $p = Get-Process -Id ([KadaiTourWin]::ProcessOf($h)) -ErrorAction SilentlyContinue
    if ($p -and $p.ProcessName -like 'KadaiSetup*') { return $h }
  }
  return [IntPtr]::Zero
}

function Get-Button([IntPtr]$Window, [string[]]$Names) {
  foreach ($c in [KadaiTourWin]::Children($Window)) {
    if (-not ([KadaiTourWin]::IsWindowVisible($c) -and [KadaiTourWin]::IsWindowEnabled($c))) { continue }
    if ([KadaiTourWin]::ClassOf($c) -notmatch 'Button') { continue }
    $text = [KadaiTourWin]::TextOf($c).Replace('&', '')
    if ($null -eq $Names -or $Names -contains $text) { return $c }
  }
  return [IntPtr]::Zero
}

# The wizard's navigation row (Back, Next/Install/Finish, Cancel): push buttons at the bottom,
# found by position so it does not depend on the captions of an Inno Setup version or language.
function Get-NavButtons([IntPtr]$Window) {
  $buttons = foreach ($c in [KadaiTourWin]::Children($Window)) {
    if (-not [KadaiTourWin]::IsWindowVisible($c)) { continue }
    $class = [KadaiTourWin]::ClassOf($c)
    if ($class -notmatch 'Button' -or $class -match 'Radio|Check') { continue }
    $r = [KadaiTourWin]::RectOf($c)
    [pscustomobject]@{ Handle = $c; Left = $r[0]; Top = $r[1]; Text = [KadaiTourWin]::TextOf($c).Replace('&', '') }
  }
  $buttons = @($buttons)
  if ($buttons.Count -eq 0) { return @() }
  $bottom = ($buttons | Measure-Object -Property Top -Maximum).Maximum
  return @($buttons | Where-Object { $_.Top -ge $bottom - 8 } | Sort-Object Left)
}

# Next (also "Install" and "Finish"): left of Cancel, or the only button left on the finish page.
function Get-NextButton([IntPtr]$Window) {
  $nav = @(Get-NavButtons $Window)
  if ($nav.Count -eq 0) { return $null }
  $next = if ($nav.Count -ge 2) { $nav[$nav.Count - 2] } else { $nav[0] }
  if (-not [KadaiTourWin]::IsWindowEnabled($next.Handle)) { return $null }
  return $next
}

function Write-Controls([IntPtr]$Window) {
  foreach ($c in [KadaiTourWin]::Children($Window)) {
    if (-not [KadaiTourWin]::IsWindowVisible($c)) { continue }
    Write-Host ("  {0,-24} '{1}' enabled={2}" -f [KadaiTourWin]::ClassOf($c), [KadaiTourWin]::TextOf($c), [KadaiTourWin]::IsWindowEnabled($c))
  }
}

function Save-Shot([IntPtr]$Window, [string]$Name) {
  $script:Shot++
  $file = Join-Path $OutDir ('{0}-{1:d2}-{2}.png' -f $Prefix, $script:Shot, $Name)
  $bmp = [KadaiTourWin]::Capture($Window)
  try { $bmp.Save($file, [Drawing.Imaging.ImageFormat]::Png) } finally { $bmp.Dispose() }
  Write-Step "saved $(Split-Path -Leaf $file)"
  return (Get-FileHash -LiteralPath $file -Algorithm MD5).Hash
}

function Wait-Until([scriptblock]$Condition, [int]$Seconds, [string]$What) {
  $deadline = (Get-Date).AddSeconds($Seconds)
  while ((Get-Date) -lt $deadline) {
    $r = & $Condition
    if ($r -and $r -ne [IntPtr]::Zero) { return $r }
    Start-Sleep -Milliseconds 400
  }
  throw "[wizard-tour] timed out after $Seconds s waiting for $What"
}

# A message box of Setup (port in use, failure...): capture it, press its first button.
function Close-MessageBox([string]$Name) {
  $box = Get-SetupWindow '#32770'
  if ($box -eq [IntPtr]::Zero) { return $false }
  Save-Shot $box $Name | Out-Null
  Write-Step "message: $(([KadaiTourWin]::Children($box) | ForEach-Object { [KadaiTourWin]::TextOf($_) } | Where-Object { $_ }) -join ' | ')"
  $button = Get-Button $box $OkNames
  if ($button -eq [IntPtr]::Zero) { $button = Get-Button $box $null }
  if ($button -ne [IntPtr]::Zero) { [KadaiTourWin]::Click($button) }
  Start-Sleep -Seconds 1
  return $true
}

$listener = $null
if ($BusyPort -gt 0) {
  $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Any, $BusyPort)
  $listener.Start()
  Write-Step "holding port $BusyPort"
}

$arguments = @("/LOG=`"$(Join-Path $OutDir "$Prefix-setup.log")`"")
if ($Lang -ne 'ask') { $arguments += "/LANG=$Lang" }
Write-Step "starting $(Split-Path -Leaf $Setup) $($arguments -join ' ')"
Start-Process -FilePath $Setup -ArgumentList $arguments | Out-Null

try {
  if ($Lang -eq 'ask') {
    $dialog = Wait-Until { Get-SetupWindow 'TSelectLanguageForm' } 120 'the language dialog'
    Start-Sleep -Seconds 1
    Save-Shot $dialog 'language' | Out-Null
    [KadaiTourWin]::Click((Get-Button $dialog $OkNames))
  }

  $wizard = Wait-Until { Get-SetupWindow 'TWizardForm' } 180 'the wizard'
  [KadaiTourWin]::SetForegroundWindow($wizard) | Out-Null
  Start-Sleep -Seconds 2

  # Welcome -> ... -> Ready: one picture per page.
  $page = 0
  while ($true) {
    $page++
    if ($page -gt 12) { throw '[wizard-tour] more pages than expected' }
    $deadline = (Get-Date).AddSeconds(60)
    $next = $null
    while (-not $next -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 400; $next = Get-NextButton $wizard }
    if (-not $next) {
      Save-Shot $wizard "page$page-stuck" | Out-Null
      Write-Controls $wizard
      throw "[wizard-tour] no enabled Next button on page $page"
    }
    Write-Step "page ${page}: buttons $((@(Get-NavButtons $wizard) | ForEach-Object { $_.Text }) -join ' | ')"
    if ($InstallNames -contains $next.Text) {
      Save-Shot $wizard 'ready' | Out-Null
      break
    }
    $before = Save-Shot $wizard "page$page"
    [KadaiTourWin]::Click($next.Handle)
    Start-Sleep -Seconds 4   # the port page checks the port before it moves on
    if (Close-MessageBox "page$page-message") {
      if ($listener) { $listener.Stop(); $listener = $null; Write-Step 'port released' }
      $page--              # same page again, this time it passes
      $script:Shot--       # and its picture replaces the first one
      continue
    }
    $bmp = [KadaiTourWin]::Capture($wizard)
    $tmp = Join-Path $OutDir '_probe.png'
    try { $bmp.Save($tmp, [Drawing.Imaging.ImageFormat]::Png) } finally { $bmp.Dispose() }
    $after = (Get-FileHash -LiteralPath $tmp -Algorithm MD5).Hash
    Remove-Item -LiteralPath $tmp -Force
    if ($after -eq $before) {
      Write-Controls $wizard
      throw "[wizard-tour] page $page did not change after Next"
    }
  }

  if (-not $Install) {
    Write-Step 'stopping at the Ready page (nothing installed)'
    return
  }

  [KadaiTourWin]::Click($next.Handle)
  $started = Get-Date
  $captureAt = @(6, 20, 45, 75, 110, 160, 220)
  $shotIndex = 0
  while ($true) {
    Start-Sleep -Seconds 2
    $elapsed = ((Get-Date) - $started).TotalSeconds
    if (Close-MessageBox 'failure') { throw '[wizard-tour] Setup reported a failure (see the picture and the logs)' }
    $done = Get-NextButton $wizard
    if ($done -and ($FinishNames -contains $done.Text -or @(Get-NavButtons $wizard).Count -eq 1)) { break }
    if ($shotIndex -lt $captureAt.Count -and $elapsed -ge $captureAt[$shotIndex]) {
      Save-Shot $wizard ('progress-{0:d3}s' -f [int]$elapsed) | Out-Null
      $shotIndex++
    }
    if ($elapsed -gt $InstallTimeoutSeconds) { throw '[wizard-tour] the installation did not finish in time' }
  }
  Start-Sleep -Seconds 1
  Save-Shot $wizard 'finish' | Out-Null
  [KadaiTourWin]::Click((Get-NextButton $wizard).Handle)
  Write-Step "installed in $([int]((Get-Date) - $started).TotalSeconds) s"

  # "Open Kadai now" starts Kadai in its own window: a picture of the desktop, best effort.
  try {
    Start-Sleep -Seconds 12
    Add-Type -AssemblyName System.Windows.Forms
    $bounds = [Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object Drawing.Bitmap $bounds.Width, $bounds.Height
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.Size)
    $g.Dispose()
    $script:Shot++
    $bmp.Save((Join-Path $OutDir ('{0}-{1:d2}-desktop.png' -f $Prefix, $script:Shot)), [Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
  } catch {
    Write-Step "no desktop picture: $($_.Exception.Message)"
  }
} finally {
  if ($listener) { $listener.Stop() }
  Get-Process -Name 'KadaiSetup*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Get-Process -Name 'msedge' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
