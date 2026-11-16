#Requires -Version 5.1
<#
.SYNOPSIS
  Builds KadaiSetup-<version>-x64.exe, the one-click offline Windows installer of Kadai Server.

.DESCRIPTION
  Run on Windows from the repository root, after .github/scripts/bundle.sh produced the native
  server bundle (kadai-server-<version>-win-x64.zip):

      powershell -ExecutionPolicy Bypass -File deploy\onprem\windows\installer\build-installer.ps1 `
        -Version 1.4.0 -Bundle dist\release\kadai-server-1.4.0-win-x64.zip

  It downloads (and caches in -WorkDir\downloads) the offline dependencies, each verified:
    - Node.js <NodeMajor> win-x64 zip      SHA-256 from nodejs.org SHASUMS256.txt
    - PostgreSQL 16 installer (EDB)        newest 16.x from -PostgresVersion, Authenticode-valid
    - WinSW v2 service wrapper              pinned URL and SHA-256 read from install.ps1
  stages them with the Windows kit (install.ps1, backup.ps1, restore.ps1, ...) and compiles
  kadai-setup.iss with Inno Setup 6 (ISCC.exe; `choco install innosetup` if missing).

  Code signing (recommended for customers; avoids the SmartScreen warning): set
  KADAI_SIGN_PFX_BASE64 (base64 of a .pfx code-signing certificate) and KADAI_SIGN_PFX_PASS.
  Setup and uninstaller are then signed with signtool.exe (Windows SDK), SHA-256 + timestamp.

  Output: <OutDir>\KadaiSetup-<version>-x64.exe
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+([-+][0-9A-Za-z.-]+)?$')][string]$Version,
  [Parameter(Mandatory = $true)][string]$Bundle,
  [string]$OutDir = 'dist\release',
  [string]$WorkDir = 'dist\.installer',
  [ValidateRange(20, 99)][int]$NodeMajor = 22,
  [ValidatePattern('^16\.\d+-\d+$')][string]$PostgresVersion = '16.15-1',
  [string]$PostgresInstaller,
  [string]$Iscc,
  [string]$TimestampUrl = 'http://timestamp.digicert.com'
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$here = $PSScriptRoot
$kitSource = Split-Path -Parent $here                     # deploy\onprem\windows
$repoRoot = (Resolve-Path (Join-Path $here '..\..\..\..')).Path

function Write-Step([string]$Message) { Write-Host "[build-installer] $Message" -ForegroundColor Green }
function Stop-Build([string]$Message) { throw "[build-installer] ERROR: $Message" }

function Get-FullPath([string]$Path) {
  if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
  return [IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Get-Sha256([string]$File) { return (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLowerInvariant() }

function Save-Download([string]$Url, [string]$OutFile) {
  if (Test-Path -LiteralPath $OutFile) { Write-Step "cached $(Split-Path -Leaf $OutFile)"; return }
  Write-Step "downloading $Url"
  $part = "$OutFile.part"
  Invoke-WebRequest -Uri $Url -OutFile $part -UseBasicParsing
  Move-Item -LiteralPath $part -Destination $OutFile -Force
}

function Test-RemoteFile([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 30
    return ($r.StatusCode -eq 200 -and $r.Headers['Content-Type'] -match 'msdos|dosexec|octet-stream')
  } catch { return $false }
}

# --- inputs -------------------------------------------------------------------------------
$Bundle = Get-FullPath $Bundle
if (-not (Test-Path -LiteralPath $Bundle)) { Stop-Build "bundle not found: $Bundle" }
$bundleName = Split-Path -Leaf $Bundle
if ($bundleName -notmatch '^kadai-server-.+-win-x64\.zip$') { Stop-Build "$bundleName is not a win-x64 server bundle" }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($Bundle)
try {
  $entries = @($zip.Entries | ForEach-Object { $_.FullName -replace '\\', '/' })
} finally { $zip.Dispose() }
foreach ($required in @('dist/server.js', 'web/index.html', 'release.json')) {
  if (-not ($entries | Where-Object { $_ -match "^[^/]+/$([regex]::Escape($required))$" })) { Stop-Build "$bundleName has no $required" }
}
if ($entries | Where-Object { $_ -match '\.pem$' }) { Stop-Build "$bundleName contains key files" }

$OutDir = Get-FullPath $OutDir
$WorkDir = Get-FullPath $WorkDir
$downloads = Join-Path $WorkDir 'downloads'
$payload = Join-Path $WorkDir 'payload'
New-Item -ItemType Directory -Force -Path $OutDir, $downloads | Out-Null
if (Test-Path -LiteralPath $payload) { Remove-Item -LiteralPath $payload -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $payload 'kit\windows'), (Join-Path $payload 'deps') | Out-Null

# --- Node.js ------------------------------------------------------------------------------
$nodeBase = "https://nodejs.org/dist/latest-v$NodeMajor.x"
$sums = (Invoke-WebRequest -Uri "$nodeBase/SHASUMS256.txt" -UseBasicParsing).Content
if ($sums -is [byte[]]) { $sums = [Text.Encoding]::UTF8.GetString($sums) }
$m = [regex]::Match($sums, "([0-9a-f]{64})\s+(node-v$NodeMajor\.\d+\.\d+-win-x64\.zip)")
if (-not $m.Success) { Stop-Build "no Node.js $NodeMajor win-x64 zip listed at $nodeBase" }
$nodeName = $m.Groups[2].Value
$nodeZip = Join-Path $downloads $nodeName
Save-Download "$nodeBase/$nodeName" $nodeZip
if ((Get-Sha256 $nodeZip) -ne $m.Groups[1].Value) { Remove-Item -LiteralPath $nodeZip -Force; Stop-Build "checksum mismatch for $nodeName" }
Write-Step "Node.js $nodeName verified"

# --- PostgreSQL ---------------------------------------------------------------------------
if ($PostgresInstaller) {
  $pgExe = Get-FullPath $PostgresInstaller
  if (-not (Test-Path -LiteralPath $pgExe)) { Stop-Build "PostgreSQL installer not found: $pgExe" }
} else {
  $minor = [int]($PostgresVersion -replace '^16\.(\d+)-\d+$', '$1')
  $url = "https://get.enterprisedb.com/postgresql/postgresql-$PostgresVersion-windows-x64.exe"
  for ($next = $minor + 1; $next -le $minor + 10; $next++) {
    $candidate = "https://get.enterprisedb.com/postgresql/postgresql-16.$next-1-windows-x64.exe"
    if (Test-RemoteFile $candidate) { $url = $candidate } else { break }
  }
  $pgExe = Join-Path $downloads (Split-Path -Leaf $url)
  Save-Download $url $pgExe
}
$signature = Get-AuthenticodeSignature -LiteralPath $pgExe
if ($signature.Status -ne 'Valid') { Stop-Build "PostgreSQL installer signature is $($signature.Status): $pgExe" }
Write-Step "PostgreSQL $(Split-Path -Leaf $pgExe) signed by $($signature.SignerCertificate.Subject)"

# --- WinSW (same pinned build as install.ps1) ---------------------------------------------
$installScript = Get-Content -LiteralPath (Join-Path $kitSource 'install.ps1') -Raw
$winswUrl = [regex]::Match($installScript, "\`$WinSWUrl = '([^']+)'").Groups[1].Value
$winswSha = [regex]::Match($installScript, "\`$WinSWSha256 = '([0-9a-f]{64})'").Groups[1].Value
if (-not $winswUrl -or -not $winswSha) { Stop-Build 'WinSW URL / SHA-256 not found in install.ps1' }
$winsw = Join-Path $downloads 'WinSW-x64.exe'
Save-Download $winswUrl $winsw
if ((Get-Sha256 $winsw) -ne $winswSha) { Remove-Item -LiteralPath $winsw -Force; Stop-Build 'checksum mismatch for WinSW-x64.exe' }
Write-Step 'WinSW verified'

# --- payload ------------------------------------------------------------------------------
$deps = Join-Path $payload 'deps'
Copy-Item -LiteralPath $Bundle -Destination $deps
Copy-Item -LiteralPath $nodeZip -Destination $deps
Copy-Item -LiteralPath $pgExe -Destination $deps
Copy-Item -LiteralPath $winsw -Destination (Join-Path $deps 'WinSW-x64.exe')
# install.ps1 verifies the bundle against SHA256SUMS next to it.
[IO.File]::WriteAllText((Join-Path $deps 'SHA256SUMS'), "$(Get-Sha256 $Bundle)  $bundleName`n", (New-Object Text.UTF8Encoding($false)))

$kit = Join-Path $payload 'kit\windows'
foreach ($f in @('install.ps1', 'backup.ps1', 'restore.ps1', 'kadai-common.ps1', 'kadai-service.xml', 'README.md')) {
  Copy-Item -LiteralPath (Join-Path $kitSource $f) -Destination $kit
}
Copy-Item -LiteralPath (Join-Path $here 'run-install.ps1') -Destination $kit
Copy-Item -LiteralPath (Join-Path $here 'README.txt') -Destination $payload
Copy-Item -LiteralPath (Join-Path $repoRoot 'apps\web\public\favicon.ico') -Destination (Join-Path $payload 'kadai.ico')

# --- compile ------------------------------------------------------------------------------
if (-not $Iscc) {
  $candidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
  )
  $Iscc = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
  if (-not $Iscc) { $cmd = Get-Command iscc.exe -ErrorAction SilentlyContinue; if ($cmd) { $Iscc = $cmd.Source } }
}
if (-not $Iscc) { Stop-Build 'Inno Setup 6 (ISCC.exe) not found: choco install innosetup, or pass -Iscc' }

$numeric = ($Version -replace '[-+].*$', '') + '.0'
$isccArgs = @(
  '/Qp',
  "/DAppVersion=$Version",
  "/DAppVersionNumeric=$numeric",
  "/DPayload=$payload",
  "/DOutputDir=$OutDir",
  "/DBundleName=$bundleName",
  "/DNodeZipName=$nodeName",
  "/DPgInstallerName=$(Split-Path -Leaf $pgExe)",
  '/DWinSWName=WinSW-x64.exe'
)

$pfxFile = $null
try {
  if ($env:KADAI_SIGN_PFX_BASE64) {
    if (-not $env:KADAI_SIGN_PFX_PASS) { Stop-Build 'KADAI_SIGN_PFX_BASE64 is set but KADAI_SIGN_PFX_PASS is not' }
    $signtool = Get-ChildItem -Path (Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin') -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -match '\\x64\\' } | Sort-Object FullName | Select-Object -Last 1
    if (-not $signtool) { Stop-Build 'signtool.exe (Windows SDK) not found' }
    $pfxFile = Join-Path $WorkDir 'codesign.pfx'
    [IO.File]::WriteAllBytes($pfxFile, [Convert]::FromBase64String($env:KADAI_SIGN_PFX_BASE64))
    # Inno Setup runs this for setup and uninstaller; $f is the file, $q a quote. The
    # certificate password is read from the environment by a tiny cmd wrapper so it never
    # appears in the ISCC command line or its log.
    $wrapper = Join-Path $WorkDir 'sign.cmd'
    [IO.File]::WriteAllText($wrapper, "@`"$($signtool.FullName)`" sign /f `"$pfxFile`" /p `"%KADAI_SIGN_PFX_PASS%`" /fd sha256 /tr $TimestampUrl /td sha256 /d `"Kadai Server`" %1`r`n")
    $isccArgs += '/DSignToolName=kadaisign'
    $isccArgs += "/Skadaisign=`$q$wrapper`$q `$f"
    Write-Step "code signing with $($signtool.FullName)"
  } else {
    Write-Warning 'KADAI_SIGN_PFX_BASE64 not set: the installer is NOT code-signed (Windows SmartScreen will warn customers)'
  }

  Write-Step "compiling with $Iscc"
  & $Iscc @isccArgs (Join-Path $here 'kadai-setup.iss')
  if ($LASTEXITCODE -ne 0) { Stop-Build "ISCC failed with exit code $LASTEXITCODE" }
} finally {
  if ($pfxFile -and (Test-Path -LiteralPath $pfxFile)) { Remove-Item -LiteralPath $pfxFile -Force }
  $wrapperFile = Join-Path $WorkDir 'sign.cmd'
  if (Test-Path -LiteralPath $wrapperFile) { Remove-Item -LiteralPath $wrapperFile -Force }
}

$setup = Join-Path $OutDir "KadaiSetup-$Version-x64.exe"
if (-not (Test-Path -LiteralPath $setup)) { Stop-Build "$setup was not produced" }
Remove-Item -LiteralPath $payload -Recurse -Force
$size = [math]::Round((Get-Item -LiteralPath $setup).Length / 1MB, 1)
Write-Step "$setup ($size MB, sha256 $(Get-Sha256 $setup))"
