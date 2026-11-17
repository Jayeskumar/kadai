#Requires -Version 5.1
<#
.SYNOPSIS
  End-to-end test of KadaiSetup-<version>-x64.exe on a throw-away Windows machine (CI runner).

.DESCRIPTION
  1. silent install      -> service running, /health/ready 200, web app served, shortcuts,
                            chosen screens (/MODULES) applied by the first-run setup
  2. port already taken  -> a second setup on a busy port is refused before installing
  3. same setup again    -> repair mode (pre-upgrade backup, switch, health check)
  4. newer one installed -> setup refuses to downgrade and changes nothing
  5. silent uninstall    -> service and program files gone, data and kadai.env kept
  6. setup again         -> reinstall mode with the kept configuration, healthy again
  Run elevated:  powershell -ExecutionPolicy Bypass -File deploy\tests\windows\installer-e2e.ps1 -Setup <exe>
  Never run this on a real shop PC: it installs and removes Kadai Server.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Setup,
  [int]$Port = 8080,
  [string]$LogDir = 'dist\installer-e2e'
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Setup = (Resolve-Path -LiteralPath $Setup).Path
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$LogDir = (Resolve-Path -LiteralPath $LogDir).Path
$installDir = Join-Path $env:ProgramFiles 'Kadai'
$dataRoot = Join-Path $env:ProgramData 'Kadai'

function Write-Step([string]$Message) { Write-Host "[installer-e2e] $Message" -ForegroundColor Cyan }
function Assert-True([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "[installer-e2e] FAILED: $Message" }
  Write-Host "  ok  $Message"
}

function Invoke-Setup([string]$Name, [string[]]$Arguments) {
  $log = Join-Path $LogDir "$Name.log"
  Write-Step "$Name : $(Split-Path -Leaf $Setup) $($Arguments -join ' ')"
  $started = Get-Date
  $p = Start-Process -FilePath $Setup -ArgumentList ($Arguments + @("/LOG=`"$log`"")) -Wait -PassThru
  Write-Step "$Name finished in $([int]((Get-Date) - $started).TotalSeconds) s with exit code $($p.ExitCode)"
  return $p.ExitCode
}

function Test-Ready {
  try {
    return ((Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health/ready" -UseBasicParsing -TimeoutSec 15).StatusCode -eq 200)
  } catch { return $false }
}

function Assert-Healthy([string]$Stage) {
  $svc = Get-Service -Name kadai -ErrorAction SilentlyContinue
  Assert-True ($null -ne $svc -and $svc.Status -eq 'Running') "$Stage : service 'kadai' is running"
  Assert-True (Test-Ready) "$Stage : /health/ready returns 200"
  $page = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/" -UseBasicParsing -TimeoutSec 15
  Assert-True ($page.StatusCode -eq 200 -and $page.Content -match '<div id="root"') "$Stage : web app is served at /"
  $account = (Get-CimInstance -ClassName Win32_Service -Filter "Name='kadai'").StartName
  Assert-True ($account -match 'LocalService') "$Stage : service runs as LocalService ($account)"
}

$silent = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-')

try {
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $dataRoot 'kadai.env'))) 'clean machine (no kadai.env)'

  # 1. install, showing only three optional screens
  $code = Invoke-Setup 'install' ($silent + @("/PORT=$Port", '/TASKS="backup,desktopicon"', '/MODULES=inventory,customers,reports', '/LANG=tamil'))
  Assert-True ($code -eq 0) 'install: setup exit code 0'
  Assert-Healthy 'install'
  $envFile = Join-Path $dataRoot 'kadai.env'
  Assert-True (Test-Path -LiteralPath $envFile) 'install: kadai.env created'
  $cfg = Get-Content -LiteralPath $envFile -Raw
  Assert-True ($cfg -match '(?m)^KADAI_MODE=onprem\r?$') 'install: KADAI_MODE=onprem'
  Assert-True ($cfg -match "(?m)^PORT=$Port\r?$") "install: PORT=$Port"
  Assert-True ($null -ne (Get-ScheduledTask -TaskName 'Kadai Backup' -ErrorAction SilentlyContinue)) 'install: backup task registered'
  Assert-True (Test-Path -LiteralPath (Join-Path $installDir 'unins000.exe')) 'install: uninstaller present'
  Assert-True (Test-Path -LiteralPath (Join-Path $installDir 'scripts\backup.ps1')) 'install: operator scripts copied'
  $secret = (Select-String -LiteralPath $envFile -Pattern '^JWT_SECRET=(.+?)\r?$').Matches[0].Groups[1].Value
  Assert-True ($cfg -match '(?m)^KADAI_MODULES=inventory,customers,reports\r?$') 'install: KADAI_MODULES written'
  $desktop = Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'Kadai.lnk'
  Assert-True (Test-Path -LiteralPath $desktop) 'install: desktop shortcut (Kadai.lnk)'
  $startMenu = Join-Path ([Environment]::GetFolderPath('CommonPrograms')) 'Kadai\Kadai.lnk'
  Assert-True (Test-Path -LiteralPath $startMenu) 'install: Start menu shortcut'
  $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($startMenu)
  Assert-True ($lnk.TargetPath -match 'msedge\.exe$' -and $lnk.Arguments -eq "--app=http://localhost:$Port/") "install: shortcut opens Kadai in an app window ($($lnk.TargetPath) $($lnk.Arguments))"

  # The shop owner completes the first-run wizard: the installer's screens are applied.
  $setupBody = @{
    business_name = 'Kaveri Stores'; business_type = 'general_store'; owner_name = 'Kaveri'
    phone = '9876501234'; password = 'Shop-Server#2026'; state_code = '33'; locale = 'ta'
  } | ConvertTo-Json
  $session = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$Port/api/v1/setup" -ContentType 'application/json' -Body $setupBody -TimeoutSec 30
  $me = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/v1/me" -Headers @{ Authorization = "Bearer $($session.data.access_token)" } -TimeoutSec 30
  $hidden = @($me.data.settings.modules.hidden) -join ','
  Assert-True ($hidden -eq 'purchases,payments,accounts,estimates,promotions,labels,notifications') "install: first-run setup hides the screens not chosen ($hidden)"

  # 2. a busy port is refused up front (not after a ten-minute install)
  $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Any, 18099)
  $listener.Start()
  try {
    # Pretend a fresh PC so Setup takes the install path. Moving (not copying) keeps the file's
    # ACL, which lets the LocalService account read it after the next restart.
    $envAside = "$envFile.e2e"
    Move-Item -LiteralPath $envFile -Destination $envAside
    try {
      $code = Invoke-Setup 'busy-port' ($silent + @('/PORT=18099'))
      Assert-True ($code -eq 7) "busy port: setup refused before installing (exit code $code)"
    } finally {
      Move-Item -LiteralPath $envAside -Destination $envFile -Force
    }
  } finally {
    $listener.Stop()
  }
  Assert-Healthy 'busy port'

  # 3. repair (same build: exercises backup, switch, rollback copy and health check)
  $code = Invoke-Setup 'repair' $silent
  Assert-True ($code -eq 0) 'repair: setup exit code 0'
  Assert-Healthy 'repair'
  Assert-True (Test-Path -LiteralPath (Join-Path $installDir 'app.prev')) 'repair: previous version kept (app.prev)'
  $dumps = @(Get-ChildItem -LiteralPath (Join-Path $dataRoot 'data\backups') -Filter '*-pre_upgrade*.dump' -ErrorAction SilentlyContinue)
  Assert-True ($dumps.Count -ge 1) "repair: pre-upgrade backup taken ($($dumps.Count) dump(s))"

  # 4. an older setup never downgrades a newer installation
  $realVersion = (Select-String -LiteralPath $envFile -Pattern '^KADAI_VERSION=(.+?)\r?$').Matches[0].Groups[1].Value
  (Get-Content -LiteralPath $envFile) -replace '^KADAI_VERSION=.*$', 'KADAI_VERSION=99.0.0' | Set-Content -LiteralPath $envFile -Encoding ASCII
  try {
    $stamp = (Get-Item -LiteralPath (Join-Path $installDir 'app')).LastWriteTimeUtc
    $code = Invoke-Setup 'downgrade' $silent
    Assert-True ($code -eq 1) "downgrade: setup refused (exit code $code)"
    Assert-True ((Get-Item -LiteralPath (Join-Path $installDir 'app')).LastWriteTimeUtc -eq $stamp) 'downgrade: program files untouched'
  } finally {
    (Get-Content -LiteralPath $envFile) -replace '^KADAI_VERSION=.*$', "KADAI_VERSION=$realVersion" | Set-Content -LiteralPath $envFile -Encoding ASCII
  }
  Assert-Healthy 'downgrade'

  # 5. uninstall (keeps data)
  $uninstaller = Join-Path $installDir 'unins000.exe'
  Write-Step 'uninstall'
  $p = Start-Process -FilePath $uninstaller -ArgumentList ($silent + @("/LOG=`"$(Join-Path $LogDir 'uninstall.log')`"")) -Wait -PassThru
  Assert-True ($p.ExitCode -eq 0) 'uninstall: exit code 0'
  # The uninstaller copies itself to %TEMP% and finishes there: wait for the files to go.
  $deadline = (Get-Date).AddSeconds(120)
  while ((Test-Path -LiteralPath (Join-Path $installDir 'app')) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 2 }
  Assert-True ($null -eq (Get-Service -Name kadai -ErrorAction SilentlyContinue)) 'uninstall: service removed'
  Assert-True (-not (Test-Path -LiteralPath (Join-Path $installDir 'app'))) 'uninstall: program files removed'
  Assert-True (Test-Path -LiteralPath $envFile) 'uninstall: kadai.env kept'
  Assert-True (-not (Test-Ready)) 'uninstall: Kadai no longer answers'
  Assert-True (-not (Test-Path -LiteralPath $desktop)) 'uninstall: desktop shortcut removed'

  # 6. reinstall with the kept configuration
  $code = Invoke-Setup 'reinstall' ($silent + @('/TASKS="desktopicon"'))
  Assert-True ($code -eq 0) 'reinstall: setup exit code 0'
  Assert-Healthy 'reinstall'
  $secretAfter = (Select-String -LiteralPath $envFile -Pattern '^JWT_SECRET=(.+?)\r?$').Matches[0].Groups[1].Value
  Assert-True ($secret -eq $secretAfter) 'reinstall: existing configuration reused'

  Write-Step 'all installer checks passed'
} catch {
  # Show the end of the newest Kadai install log right in the CI output.
  $last = Get-ChildItem -Path (Join-Path $dataRoot 'logs') -Filter 'install-*.log' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime | Select-Object -Last 1
  if ($last) {
    Write-Host "----- $($last.FullName) (last 40 lines) -----"
    Get-Content -LiteralPath $last.FullName -Tail 40 | ForEach-Object { Write-Host $_ }
  }
  throw
} finally {
  # Keep everything useful for diagnosis next to the setup logs.
  $logs = Join-Path $dataRoot 'logs'
  if (Test-Path -LiteralPath $logs) { Copy-Item -Path (Join-Path $logs '*') -Destination $LogDir -Recurse -Force -ErrorAction SilentlyContinue }
}
