#Requires -Version 5.1
<#
.SYNOPSIS
  Runs install.ps1 for KadaiSetup.exe (the Inno Setup installer): unattended, with a log file
  and an exit-code file the installer polls while it shows progress.

.DESCRIPTION
  KadaiSetup.exe extracts the kit, the server bundle and the offline dependencies (Node.js,
  PostgreSQL, WinSW) into its temporary folder, then starts this script hidden. The script
  never prompts: every answer comes from a parameter. A transcript of the whole run goes to
  -LogFile; "0" (success) or "1" (failure) is written to -ExitCodeFile at the very end.

  The PostgreSQL superuser password of an existing PostgreSQL 16 installation (if any) is
  passed in a file (-PgSecretFile) that is deleted as soon as it is read, never on a command
  line.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$LogFile,
  [Parameter(Mandatory = $true)][string]$ExitCodeFile,
  [ValidateSet('Install', 'Upgrade', 'Reinstall')][string]$Mode = 'Install',
  [Parameter(Mandatory = $true)][string]$InstallDir,
  [Parameter(Mandatory = $true)][string]$BundlePath,
  [Parameter(Mandatory = $true)][string]$NodeZip,
  [string]$PostgresInstaller,
  [string]$WinSWExe,
  [ValidateRange(1, 65535)][int]$Port = 8080,
  [string]$PgSecretFile,
  [switch]$SetNetworkPrivate,
  [switch]$BackupTask,
  [switch]$NoShortcut
)

$ErrorActionPreference = 'Stop'
$code = 1
$transcript = $false
try {
  $logDir = Split-Path -Parent $LogFile
  if ($logDir) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
  try {
    Start-Transcript -LiteralPath $LogFile -Append | Out-Null
    $transcript = $true
  } catch {
    Write-Warning "no transcript: $($_.Exception.Message)"
  }
  Write-Host "[kadai] KadaiSetup: mode $Mode, install folder $InstallDir"

  $arguments = @{
    Yes        = $true
    InstallDir = $InstallDir
    BundlePath = $BundlePath
    NodeZip    = $NodeZip
  }
  if ($Mode -eq 'Upgrade') {
    $arguments['Upgrade'] = $true
  } else {
    # Install: new configuration. Reinstall: existing kadai.env (port, secrets) after an
    # uninstall that kept the data, or to repair the application files and the service.
    if ($Mode -eq 'Reinstall') { $arguments['Reinstall'] = $true } else { $arguments['Port'] = $Port }
    if ($PostgresInstaller) { $arguments['PostgresInstaller'] = $PostgresInstaller }
    if ($WinSWExe) { $arguments['WinSWExe'] = $WinSWExe }
    if ($SetNetworkPrivate) { $arguments['SetNetworkPrivate'] = $true }
    if ($BackupTask) { $arguments['BackupTask'] = $true }
    if ($NoShortcut) { $arguments['NoShortcut'] = $true }
    if ($PgSecretFile -and (Test-Path -LiteralPath $PgSecretFile)) {
      $plain = (Get-Content -LiteralPath $PgSecretFile -Raw).Trim()
      Remove-Item -LiteralPath $PgSecretFile -Force
      $secure = New-Object Security.SecureString
      foreach ($ch in $plain.ToCharArray()) { $secure.AppendChar($ch) }
      $secure.MakeReadOnly()
      $arguments['PostgresSuperPassword'] = $secure
      $plain = $null
    }
  }

  & (Join-Path $PSScriptRoot 'install.ps1') @arguments
  $code = 0
  Write-Host '[kadai] KadaiSetup: finished'
} catch {
  # Stop-WithError messages already start with "[kadai] ERROR:"; KadaiSetup.exe shows the
  # last such line to the user.
  $message = $_.Exception.Message
  if ($message -notmatch '^\[kadai\] ERROR:') { $message = "[kadai] ERROR: $message" }
  Write-Host $message
  Write-Host $_.ScriptStackTrace
} finally {
  if ($PgSecretFile -and (Test-Path -LiteralPath $PgSecretFile)) { Remove-Item -LiteralPath $PgSecretFile -Force -ErrorAction SilentlyContinue }
  if ($transcript) { Stop-Transcript | Out-Null }
  [IO.File]::WriteAllText($ExitCodeFile, [string]$code)
}
exit $code
