; KadaiSetup-<version>-x64.exe: one-click, offline installer of Kadai Server for a Windows shop PC.
;
; Built by build-installer.ps1 (Inno Setup 6.3+), which stages the payload and passes:
;   /DAppVersion=1.4.0  /DAppVersionNumeric=1.4.0.0  /DPayload=<staged folder>
;   /DBundleName=kadai-server-1.4.0-win-x64.zip  /DNodeZipName=node-v22.x.y-win-x64.zip
;   /DPgInstallerName=postgresql-16.x-1-windows-x64.exe  /DWinSWName=WinSW-x64.exe
;   [/DSignToolName=kadaisign together with /Skadaisign=...]   (code signing, optional)
;
; What the .exe does: it carries the on-prem Windows kit (install.ps1 and friends), the native
; server bundle, Node.js 22, PostgreSQL 16 and WinSW, and runs install.ps1 unattended through
; run-install.ps1 while it shows progress. Three modes, chosen automatically:
;   Install    no C:\ProgramData\Kadai\kadai.env yet: new installation (port page, options)
;   Upgrade    kadai.env and the "kadai" service exist: pre-upgrade backup, switch, health check
;   Reinstall  kadai.env exists but the service was removed: reuse configuration and database
; Uninstall removes the service, firewall rule, shortcuts and program files; the data folder,
; the backups and the PostgreSQL database are kept.
;
; Silent install (IT staff):  KadaiSetup-<v>-x64.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
;   [/PORT=8080] [/TASKS="network,backup,desktopicon"] [/PGPASSWORD=...] [/LOG=C:\kadai-setup.log]
;   Exit code 0 = installed and healthy; 7 = Kadai could not be installed (see the log).

#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif
#ifndef AppVersionNumeric
  #define AppVersionNumeric "0.0.0.0"
#endif
#ifndef Payload
  #error "Pass /DPayload=<folder staged by build-installer.ps1>"
#endif
#ifndef BundleName
  #error "Pass /DBundleName=kadai-server-<version>-win-x64.zip"
#endif
#ifndef NodeZipName
  #error "Pass /DNodeZipName=node-v22.x.y-win-x64.zip"
#endif
#ifndef PgInstallerName
  #error "Pass /DPgInstallerName=postgresql-16.x-1-windows-x64.exe"
#endif
#ifndef OutputDir
  #define OutputDir "output"
#endif
#ifndef WinSWName
  #define WinSWName "WinSW-x64.exe"
#endif

[Setup]
AppId={{6B0F3C1E-4D7A-4C2B-9A55-2E8F7D1C0A4B}
AppName=Kadai Server
AppVersion={#AppVersion}
AppVerName=Kadai Server {#AppVersion}
AppPublisher=Kadai
AppPublisherURL=https://github.com/Jayeskumar/kadai
AppSupportURL=https://github.com/Jayeskumar/kadai
AppComments=Billing, stock, GST and UPI for your shop
VersionInfoVersion={#AppVersionNumeric}
VersionInfoProductVersion={#AppVersionNumeric}
VersionInfoProductTextVersion={#AppVersion}
VersionInfoDescription=Kadai Server setup
DefaultDirName={autopf}\Kadai
; install.ps1 manages <InstallDir>\{app,node,service,scripts}; keep one fixed, supported place.
DisableDirPage=yes
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=KadaiSetup-{#AppVersion}-x64
SetupIconFile={#Payload}\kadai.ico
UninstallDisplayIcon={app}\kadai.ico
UninstallDisplayName=Kadai Server
WizardStyle=modern
Compression=lzma2/normal
SolidCompression=no
LZMAUseSeparateProcess=yes
CloseApplications=no
RestartIfNeededByRun=no
SetupLogging=yes
ShowLanguageDialog=no
#ifdef SignToolName
SignTool={#SignToolName}
SignedUninstaller=yes
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel2=This installs Kadai Server {#AppVersion} - billing, stock, GST and UPI for your shop - on this PC.%n%nSetup also installs PostgreSQL 16 (the database) and a private Node.js runtime, and runs Kadai as the Windows service "Kadai Server". Other PCs, phones and tablets on the shop network then open Kadai in their browser.%n%nNo internet connection is needed. Installation takes about 5-10 minutes.
FinishedHeadingLabel=Kadai Server is ready

[Tasks]
Name: "network"; Description: "Let counter PCs, phones and tablets on this shop network connect (marks the network as Private)"; Check: not IsUpgrade
Name: "backup"; Description: "Back up the database every day at 22:45"; Check: not IsUpgrade
Name: "desktopicon"; Description: "Create a ""Kadai"" shortcut on the desktop"; Check: not IsUpgrade

[Files]
; Extracted to {tmp} by PrepareToInstall (dontcopy) and used by install.ps1; {tmp} is removed
; when Setup ends. install.ps1 copies the operator scripts to {app}\scripts itself.
Source: "{#Payload}\kit\windows\*"; DestDir: "{tmp}\kit\windows"; Flags: dontcopy
Source: "{#Payload}\deps\*"; DestDir: "{tmp}\deps"; Flags: dontcopy nocompression
Source: "{#Payload}\kadai.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Payload}\README.txt"; DestDir: "{app}"; Flags: ignoreversion

[INI]
Filename: "{app}\Kadai.url"; Section: "InternetShortcut"; Key: "URL"; String: "http://localhost:{code:GetPort}/"
Filename: "{app}\Kadai.url"; Section: "InternetShortcut"; Key: "IconFile"; String: "{app}\kadai.ico"
Filename: "{app}\Kadai.url"; Section: "InternetShortcut"; Key: "IconIndex"; String: "0"

[Icons]
Name: "{autoprograms}\Kadai\Kadai"; Filename: "{app}\Kadai.url"; IconFilename: "{app}\kadai.ico"
Name: "{autoprograms}\Kadai\Kadai logs"; Filename: "{commonappdata}\Kadai\logs"
Name: "{autoprograms}\Kadai\Kadai guide"; Filename: "{app}\README.txt"
Name: "{autoprograms}\Kadai\Uninstall Kadai Server"; Filename: "{uninstallexe}"

[Run]
Filename: "http://localhost:{code:GetPort}/"; Description: "Open Kadai now"; Flags: shellexec postinstall nowait skipifsilent

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File ""{app}\scripts\install.ps1"" -Uninstall -Yes -InstallDir ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "KadaiUninstall"; StatusMsg: "Stopping and removing the Kadai Server service..."

[UninstallDelete]
Type: filesandordirs; Name: "{app}\app"
Type: filesandordirs; Name: "{app}\app.prev"
Type: filesandordirs; Name: "{app}\app.new"
Type: filesandordirs; Name: "{app}\app.failed"
Type: filesandordirs; Name: "{app}\node"
Type: filesandordirs; Name: "{app}\service"
Type: filesandordirs; Name: "{app}\scripts"
Type: files; Name: "{app}\Kadai.url"
Type: dirifempty; Name: "{app}"

[Code]
const
  PgServiceKey = 'SYSTEM\CurrentControlSet\Services\postgresql-x64-16';
  KadaiServiceKey = 'SYSTEM\CurrentControlSet\Services\kadai';
  InstallTimeoutSeconds = 3600;
  ExpectedSteps = 16;

var
  Mode: String;            { Install | Upgrade | Reinstall }
  NeedPgPassword: Boolean;
  PortPage: TInputQueryWizardPage;
  PgPage: TInputQueryWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  InstallLog: String;

function DataRoot(): String;
begin
  Result := ExpandConstant('{commonappdata}\Kadai');
end;

function EnvFilePath(): String;
begin
  Result := DataRoot() + '\kadai.env';
end;

function IsUpgrade(): Boolean;
begin
  Result := Mode = 'Upgrade';
end;

{ PORT=... from the existing kadai.env (upgrade / reinstall). }
function ReadEnvPort(): String;
var
  Lines: TArrayOfString;
  I: Integer;
  L: String;
begin
  Result := '8080';
  if LoadStringsFromFile(EnvFilePath(), Lines) then
    for I := 0 to GetArrayLength(Lines) - 1 do
    begin
      L := Trim(Lines[I]);
      if Pos('PORT=', L) = 1 then
      begin
        Result := Trim(Copy(L, 6, Length(L)));
        Exit;
      end;
    end;
end;

function GetPort(Param: String): String;
begin
  if Mode = 'Install' then
    Result := Trim(PortPage.Values[0])
  else
    Result := ReadEnvPort();
end;

function InitializeSetup(): Boolean;
begin
  if FileExists(EnvFilePath()) then
  begin
    if RegKeyExists(HKLM, KadaiServiceKey) then Mode := 'Upgrade' else Mode := 'Reinstall';
  end else
    Mode := 'Install';
  NeedPgPassword := (Mode = 'Install') and RegKeyExists(HKLM, PgServiceKey) and
    not FileExists(DataRoot() + '\secrets\postgres-superuser.txt');
  Log('Kadai setup mode: ' + Mode);
  Result := True;
end;

procedure InitializeWizard();
begin
  PortPage := CreateInputQueryPage(wpSelectTasks, 'Network port',
    'Which port should Kadai Server use?',
    'Counter PCs, phones and tablets on the shop network open http://<this PC>:<port>. ' +
    'Keep 8080 unless another program on this PC already uses it.');
  PortPage.Add('&Port:', False);
  PortPage.Values[0] := ExpandConstant('{param:PORT|8080}');

  PgPage := CreateInputQueryPage(PortPage.ID, 'PostgreSQL',
    'PostgreSQL 16 is already installed on this PC',
    'Kadai creates its own database and roles in it. Enter the password of its "postgres" superuser.');
  PgPage.Add('&Password of the "postgres" user:', True);
  PgPage.Values[0] := ExpandConstant('{param:PGPASSWORD|}');

  ProgressPage := CreateOutputProgressPage('Installing Kadai Server',
    'Setting up PostgreSQL, the database and the Kadai Server service. This takes a few minutes.');
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if PageID = PortPage.ID then Result := Mode <> 'Install';
  if PageID = PgPage.ID then Result := not NeedPgPassword;
end;

function ValidPort(Value: String): Boolean;
var
  P: Integer;
begin
  P := StrToIntDef(Trim(Value), 0);
  Result := (P >= 1) and (P <= 65535);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = PortPage.ID) and not ValidPort(PortPage.Values[0]) then
  begin
    MsgBox('Enter a port number between 1 and 65535.', mbError, MB_OK);
    Result := False;
  end;
  if (CurPageID = PgPage.ID) and (Trim(PgPage.Values[0]) = '') then
  begin
    MsgBox('Enter the password of the PostgreSQL "postgres" user.', mbError, MB_OK);
    Result := False;
  end;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
begin
  if Mode = 'Upgrade' then
    Result := 'Upgrade Kadai Server to {#AppVersion}.' + NewLine + Space +
      'A backup of the database is taken first; the previous version is kept for rollback.'
  else if Mode = 'Reinstall' then
    Result := 'Reinstall Kadai Server {#AppVersion} with the existing configuration and data in ' + DataRoot() + '.'
  else
    Result := 'Install Kadai Server {#AppVersion}, PostgreSQL 16 and Node.js.' + NewLine + Space +
      'Address on this network: http://' + Lowercase(GetComputerNameString()) + ':' + GetPort('');
  Result := Result + NewLine + NewLine + 'Program folder:' + NewLine + Space + ExpandConstant('{app}') +
    NewLine + 'Data, backups and logs:' + NewLine + Space + DataRoot();
  if MemoTasksInfo <> '' then Result := Result + NewLine + NewLine + MemoTasksInfo;
end;

{ Last "[kadai] ..." line of the install log, for progress and error messages. }
function LastKadaiLine(var Count: Integer; ErrorsOnly: Boolean): String;
var
  Lines: TArrayOfString;
  I: Integer;
  L: String;
begin
  Result := '';
  Count := 0;
  if not LoadStringsFromFile(InstallLog, Lines) then Exit;
  for I := 0 to GetArrayLength(Lines) - 1 do
  begin
    L := Trim(Lines[I]);
    if Pos('[kadai] ', L) = 1 then
    begin
      Count := Count + 1;
      if (not ErrorsOnly) or (Pos('[kadai] ERROR:', L) = 1) then Result := Copy(L, 9, Length(L));
    end;
  end;
end;

function Quote(S: String): String;
begin
  Result := '"' + S + '"';
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Params, KitDir, DepsDir, ExitFile, SecretFile, Status: String;
  ExitText: AnsiString;
  ResultCode, Waited, Steps: Integer;
begin
  Result := '';
  if (Mode = 'Install') and not ValidPort(GetPort('')) then
  begin
    Result := 'Invalid port "' + GetPort('') + '": pass /PORT=<1-65535>.';
    Exit;
  end;
  if NeedPgPassword and (Trim(PgPage.Values[0]) = '') then
  begin
    Result := 'PostgreSQL 16 is already installed on this PC: its "postgres" password is needed (/PGPASSWORD=...).';
    Exit;
  end;

  if not WizardSilent() then
  begin
    ProgressPage.SetText('Unpacking...', '');
    ProgressPage.SetProgress(0, ExpectedSteps);
    ProgressPage.Show();
  end;
  try
    ExtractTemporaryFiles('{tmp}\kit\windows\*');
    ExtractTemporaryFiles('{tmp}\deps\*');

    KitDir := ExpandConstant('{tmp}\kit\windows');
    DepsDir := ExpandConstant('{tmp}\deps');
    ExitFile := ExpandConstant('{tmp}\kadai-exit-code.txt');
    InstallLog := DataRoot() + '\logs\install-' + GetDateTimeString('yyyymmdd-hhnnss', '-', '-') + '.log';
    Log('Kadai install log: ' + InstallLog);

    Params := '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' + Quote(KitDir + '\run-install.ps1') +
      ' -Mode ' + Mode +
      ' -LogFile ' + Quote(InstallLog) +
      ' -ExitCodeFile ' + Quote(ExitFile) +
      ' -InstallDir ' + Quote(ExpandConstant('{app}')) +
      ' -BundlePath ' + Quote(DepsDir + '\{#BundleName}') +
      ' -NodeZip ' + Quote(DepsDir + '\{#NodeZipName}');
    if Mode <> 'Upgrade' then
    begin
      Params := Params +
        ' -PostgresInstaller ' + Quote(DepsDir + '\{#PgInstallerName}') +
        ' -WinSWExe ' + Quote(DepsDir + '\{#WinSWName}');
      if Mode = 'Install' then Params := Params + ' -Port ' + GetPort('');
      if WizardIsTaskSelected('network') then Params := Params + ' -SetNetworkPrivate';
      if WizardIsTaskSelected('backup') then Params := Params + ' -BackupTask';
      if not WizardIsTaskSelected('desktopicon') then Params := Params + ' -NoShortcut';
    end;
    if NeedPgPassword then
    begin
      // The temporary folder is private to this administrator; run-install.ps1 deletes the
      // file as soon as it has read it.
      SecretFile := ExpandConstant('{tmp}\pg-superuser.txt');
      if not SaveStringToFile(SecretFile, Trim(PgPage.Values[0]), False) then
      begin
        Result := 'Could not write a temporary file in ' + ExpandConstant('{tmp}') + '.';
        Exit;
      end;
      Params := Params + ' -PgSecretFile ' + Quote(SecretFile);
    end;

    if not Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Params, KitDir,
      SW_HIDE, ewNoWait, ResultCode) then
    begin
      Result := 'Windows PowerShell could not be started: ' + SysErrorMessage(ResultCode);
      Exit;
    end;

    Waited := 0;
    while not FileExists(ExitFile) do
    begin
      Sleep(500);
      Waited := Waited + 1;
      if not WizardSilent() then
      begin
        Status := LastKadaiLine(Steps, False);
        if Steps > ExpectedSteps then Steps := ExpectedSteps;
        ProgressPage.SetText('Installing Kadai Server...', Status);
        ProgressPage.SetProgress(Steps, ExpectedSteps);
      end;
      if Waited > InstallTimeoutSeconds * 2 then
      begin
        Result := 'The installation did not finish within ' + IntToStr(InstallTimeoutSeconds div 60) +
          ' minutes. See the log: ' + InstallLog;
        Exit;
      end;
    end;

    Sleep(500);
    if not LoadStringFromFile(ExitFile, ExitText) then ExitText := '1';
    if Trim(ExitText) <> '0' then
    begin
      Status := LastKadaiLine(Steps, True);
      if Status = '' then Status := 'the installation script failed.';
      Result := 'Kadai Server could not be installed: ' + Status + #13#10#13#10 +
        'Full log: ' + InstallLog + #13#10 +
        'Fix the problem and run Setup again (it continues where it stopped), or send the log to support.';
      Exit;
    end;
    Log('Kadai installation script finished');
  finally
    if not WizardSilent() then ProgressPage.Hide();
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
    WizardForm.FinishedLabel.Caption :=
      'Kadai Server is installed and running as a Windows service.' + #13#10#13#10 +
      'On this PC open the "Kadai" shortcut (http://localhost:' + GetPort('') + ').' + #13#10 +
      'Counter PCs, phones and tablets open http://' + Lowercase(GetComputerNameString()) + ':' + GetPort('') + #13#10#13#10 +
      'First visit: complete the setup wizard (shop name, GSTIN, owner login), then upload the licence in Settings > System.' + #13#10#13#10 +
      'Keep a copy of ' + EnvFilePath() + ' on a USB drive: it is needed to restore Kadai on a new PC.';
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and not UninstallSilent() then
    MsgBox('Kadai Server was removed.' + #13#10#13#10 +
      'Your shop data, backups and the PostgreSQL database are kept in ' + DataRoot() +
      ' and PostgreSQL 16. Running KadaiSetup again reuses them.', mbInformation, MB_OK);
end;
