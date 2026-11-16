#Requires -Version 5.1
<#
.SYNOPSIS
  End-to-end test of KadaiSetup-<version>-x64.exe on a throw-away Windows machine (CI runner).

.DESCRIPTION
  1. silent install      -> service running, /health/ready 200, web app and setup status served
  2. same setup again    -> upgrade mode (pre-upgrade backup, switch, health check)
  3. silent uninstall    -> service and program files gone, data and kadai.env kept
  4. setup again         -> reinstall mode with the kept configuration, healthy again
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

  # 1. install
  $code = Invoke-Setup 'install' ($silent + @("/PORT=$Port", '/TASKS="backup,desktopicon"'))
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

  # 2. upgrade (same build: exercises backup, switch, rollback copy and health check)
  $code = Invoke-Setup 'upgrade' $silent
  Assert-True ($code -eq 0) 'upgrade: setup exit code 0'
  Assert-Healthy 'upgrade'
  Assert-True (Test-Path -LiteralPath (Join-Path $installDir 'app.prev')) 'upgrade: previous version kept (app.prev)'
  $dumps = @(Get-ChildItem -LiteralPath (Join-Path $dataRoot 'data\backups') -Filter '*-pre_upgrade*.dump' -ErrorAction SilentlyContinue)
  Assert-True ($dumps.Count -ge 1) "upgrade: pre-upgrade backup taken ($($dumps.Count) dump(s))"

  # 3. uninstall (keeps data)
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

  # 4. reinstall with the kept configuration
  $code = Invoke-Setup 'reinstall' ($silent + @('/TASKS="desktopicon"'))
  Assert-True ($code -eq 0) 'reinstall: setup exit code 0'
  Assert-Healthy 'reinstall'
  $secretAfter = (Select-String -LiteralPath $envFile -Pattern '^JWT_SECRET=(.+?)\r?$').Matches[0].Groups[1].Value
  Assert-True ($secret -eq $secretAfter) 'reinstall: existing configuration reused'

  Write-Step 'all installer checks passed'
} finally {
  # Keep everything useful for diagnosis next to the setup logs.
  $logs = Join-Path $dataRoot 'logs'
  if (Test-Path -LiteralPath $logs) { Copy-Item -Path (Join-Path $logs '*') -Destination $LogDir -Recurse -Force -ErrorAction SilentlyContinue }
}
