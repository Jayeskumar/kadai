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
; run-install.ps1 while it shows friendly progress. Modes, chosen automatically:
;   Install    no C:\ProgramData\Kadai\kadai.env yet: new installation (options, screens, port)
;   Upgrade    kadai.env + "kadai" service, older version: backup, switch, health check
;   Repair     the same version again: reinstall program files and service, data untouched
;   Reinstall  kadai.env exists but the service was removed: reuse configuration and database
;   (a NEWER installed version is refused: migrations are forward-only, downgrades break Kadai)
; Uninstall removes the service, firewall rule, shortcuts and program files; the data folder,
; the backups and the PostgreSQL database are kept.
;
; Texts: lang\English.isl and lang\Tamil.isl (UTF-8 with BOM). Images: assets\ (rendered by
; assets\render-assets.mjs from the Kadai logo).
;
; Silent install (IT staff):  KadaiSetup-<v>-x64.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
;   [/PORT=8080] [/TASKS="network,backup,desktopicon"] [/MODULES=inventory,customers,reports]
;   [/PGPASSWORDFILE=C:\pg.txt | /PGPASSWORD=...] [/LANG=tamil] [/LOG=C:\kadai-setup.log]
;   /MODULES lists the optional screens to show ("all", the default, or "none" = billing only).
;   Prefer /PGPASSWORDFILE: Inno Setup writes the whole command line into its /LOG file.
;   Exit codes: 0 = installed and healthy; 1 = refused (e.g. newer version installed);
;   7 = Kadai could not be installed (see C:\ProgramData\Kadai\logs\install-*.log).

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
; Inno Setup 6 hides the welcome page by default; ours carries the banner and the overview.
DisableWelcomePage=no
UsePreviousAppDir=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
; Two setups at the same time would race on the service and the database.
SetupMutex=KadaiSetupMutex,Global\KadaiSetupMutex
; PostgreSQL, Node.js, the unpacked server and the first data need room beyond Setup's own files.
ExtraDiskSpaceRequired=1610612736
OutputDir={#OutputDir}
OutputBaseFilename=KadaiSetup-{#AppVersion}-x64
SetupIconFile={#Payload}\assets\kadai.ico
UninstallDisplayIcon={app}\kadai.ico
UninstallDisplayName=Kadai Server
WizardStyle=modern
WizardSizePercent=120
WizardImageFile={#Payload}\assets\wizard-164x314.bmp,{#Payload}\assets\wizard-246x459.bmp,{#Payload}\assets\wizard-328x604.bmp
WizardSmallImageFile={#Payload}\assets\small-55x55.bmp,{#Payload}\assets\small-83x80.bmp,{#Payload}\assets\small-110x106.bmp
Compression=lzma2/normal
SolidCompression=no
LZMAUseSeparateProcess=yes
CloseApplications=no
RestartIfNeededByRun=no
SetupLogging=yes
ShowLanguageDialog=yes
LanguageDetectionMethod=uilanguage
#ifdef SignToolName
SignTool={#SignToolName}
SignedUninstaller=yes
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl,lang\English.isl"
Name: "tamil"; MessagesFile: "compiler:Default.isl,lang\Tamil.isl"

[Tasks]
Name: "network"; Description: "{cm:TaskNetwork}"; GroupDescription: "{cm:GroupNetwork}"; Check: ShowTasks
Name: "backup"; Description: "{cm:TaskBackup}"; GroupDescription: "{cm:GroupBackup}"; Check: ShowTasks
Name: "desktopicon"; Description: "{cm:TaskDesktop}"; GroupDescription: "{cm:GroupShortcuts}"; Check: ShowTasks

[Files]
; Extracted to {tmp} by PrepareToInstall (dontcopy) and used by install.ps1; {tmp} is removed
; when Setup ends. install.ps1 copies the operator scripts to {app}\scripts itself.
Source: "{#Payload}\kit\windows\*"; DestDir: "{tmp}\kit\windows"; Flags: dontcopy
Source: "{#Payload}\deps\*"; DestDir: "{tmp}\deps"; Flags: dontcopy nocompression
Source: "{#Payload}\assets\kadai.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Payload}\README.txt"; DestDir: "{app}"; Flags: ignoreversion

[INI]
; Fallback shortcut target when Microsoft Edge is missing (opens the default browser).
Filename: "{app}\Kadai.url"; Section: "InternetShortcut"; Key: "URL"; String: "http://localhost:{code:GetPort}/"
Filename: "{app}\Kadai.url"; Section: "InternetShortcut"; Key: "IconFile"; String: "{app}\kadai.ico"
Filename: "{app}\Kadai.url"; Section: "InternetShortcut"; Key: "IconIndex"; String: "0"

[Icons]
; Kadai opens in its own app window (Edge --app), like an installed program, not a browser tab.
Name: "{autoprograms}\Kadai\Kadai"; Filename: "{code:EdgeExe}"; Parameters: "--app=http://localhost:{code:GetPort}/"; IconFilename: "{app}\kadai.ico"; Comment: "Kadai"; Check: HasEdge
Name: "{autoprograms}\Kadai\Kadai"; Filename: "{app}\Kadai.url"; IconFilename: "{app}\kadai.ico"; Check: not HasEdge
Name: "{autodesktop}\Kadai"; Filename: "{code:EdgeExe}"; Parameters: "--app=http://localhost:{code:GetPort}/"; IconFilename: "{app}\kadai.ico"; Comment: "Kadai"; Tasks: desktopicon; Check: HasEdge
Name: "{autodesktop}\Kadai"; Filename: "{app}\Kadai.url"; IconFilename: "{app}\kadai.ico"; Tasks: desktopicon; Check: not HasEdge
Name: "{autoprograms}\Kadai\{cm:IconLogs}"; Filename: "{commonappdata}\Kadai\logs"
Name: "{autoprograms}\Kadai\{cm:IconGuide}"; Filename: "{app}\README.txt"
Name: "{autoprograms}\Kadai\{cm:IconUninstall}"; Filename: "{uninstallexe}"

[Run]
; runasoriginaluser: Setup is elevated, the browser must not be.
Filename: "{code:EdgeExe}"; Parameters: "--app=http://localhost:{code:GetPort}/"; Description: "{cm:RunOpen}"; Flags: postinstall nowait skipifsilent runasoriginaluser; Check: HasEdge
Filename: "http://localhost:{code:GetPort}/"; Description: "{cm:RunOpen}"; Flags: shellexec postinstall nowait skipifsilent runasoriginaluser; Check: not HasEdge

[UninstallRun]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File ""{app}\scripts\install.ps1"" -Uninstall -Yes -InstallDir ""{app}"""; Flags: runhidden waituntilterminated; RunOnceId: "KadaiUninstall"; StatusMsg: "{cm:UninstallStatus}"

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
  { Friendly progress: steps 0..StepLast, see StepOf / StepKey. }
  StepLast = 11;

var
  Mode: String;             { Install | Upgrade | Repair | Reinstall }
  InstalledVersion: String;
  NeedPgPassword: Boolean;
  ModuleIds: TArrayOfString;
  ModulesPage: TWizardPage;
  ModulesList: TNewCheckListBox;
  ModuleDesc: TNewStaticText;
  PortPage: TInputQueryWizardPage;
  PgPage: TInputQueryWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  InstallLog: String;
  LanUrls: TArrayOfString;

{ ---------------------------------------------------------------------------------------- }
{ Helpers                                                                                  }
{ ---------------------------------------------------------------------------------------- }

procedure InitModuleIds();
begin
  // Optional screens, in the order of packages/shared/src/modules.ts (APP_MODULES); kept in
  // sync by packages/shared/test/modules.test.ts. Labels: Module_<id> in lang\*.isl.
  SetArrayLength(ModuleIds, 10);
  // BEGIN APP_MODULES
  ModuleIds[0] := 'inventory';
  ModuleIds[1] := 'purchases';
  ModuleIds[2] := 'customers';
  ModuleIds[3] := 'payments';
  ModuleIds[4] := 'accounts';
  ModuleIds[5] := 'reports';
  ModuleIds[6] := 'estimates';
  ModuleIds[7] := 'promotions';
  ModuleIds[8] := 'labels';
  ModuleIds[9] := 'notifications';
  // END APP_MODULES
end;

function DataRoot(): String;
begin
  Result := ExpandConstant('{commonappdata}\Kadai');
end;

function EnvFilePath(): String;
begin
  Result := DataRoot() + '\kadai.env';
end;

function PowerShellExe(): String;
begin
  Result := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
end;

function Quote(S: String): String;
begin
  Result := '"' + S + '"';
end;

{ KEY=value from the existing kadai.env ('' when absent). }
function ReadEnvValue(Key: String): String;
var
  Lines: TArrayOfString;
  I: Integer;
  L: String;
begin
  Result := '';
  if LoadStringsFromFile(EnvFilePath(), Lines) then
    for I := 0 to GetArrayLength(Lines) - 1 do
    begin
      L := Trim(Lines[I]);
      if Pos(Key + '=', L) = 1 then
      begin
        Result := Trim(Copy(L, Length(Key) + 2, Length(L)));
        Exit;
      end;
    end;
end;

function ShowTasks(): Boolean;
begin
  Result := (Mode = 'Install') or (Mode = 'Reinstall');
end;

function GetPort(Param: String): String;
begin
  if Mode = 'Install' then
    Result := Trim(PortPage.Values[0])
  else
  begin
    Result := ReadEnvValue('PORT');
    if Result = '' then Result := '8080';
  end;
end;

function EdgeExe(Param: String): String;
begin
  Result := ExpandConstant('{commonpf32}\Microsoft\Edge\Application\msedge.exe');
  if not FileExists(Result) then
    Result := ExpandConstant('{commonpf64}\Microsoft\Edge\Application\msedge.exe');
end;

function HasEdge(): Boolean;
begin
  Result := FileExists(EdgeExe(''));
end;

function ValidPort(Value: String): Boolean;
var
  P: Integer;
begin
  P := StrToIntDef(Trim(Value), 0);
  Result := (P >= 1) and (P <= 65535);
end;

{ True when another program already listens on the port (checked before a long install). }
function PortInUse(Port: String): Boolean;
var
  RC: Integer;
begin
  Result := False;
  if Exec(PowerShellExe(), '-NoProfile -NonInteractive -Command "if (Get-NetTCPConnection -State Listen -LocalPort ' +
    Port + ' -ErrorAction SilentlyContinue) { exit 3 } else { exit 0 }"', '', SW_HIDE, ewWaitUntilTerminated, RC) then
    Result := RC = 3;
end;

{ n-th dot-separated number of a version core ("1.12.3" -> 0:1, 1:12, 2:3). }
function VersionPart(Core: String; N: Integer): Integer;
var
  I, P: Integer;
begin
  for I := 1 to N do
  begin
    P := Pos('.', Core);
    if P = 0 then
    begin
      Result := 0;
      Exit;
    end;
    Core := Copy(Core, P + 1, Length(Core));
  end;
  P := Pos('.', Core);
  if P > 0 then Core := Copy(Core, 1, P - 1);
  Result := StrToIntDef(Core, 0);
end;

{ <0, 0, >0 like a comparison of semantic versions; a pre-release sorts before its release. }
function CompareVersion(A, B: String): Integer;
var
  PA, PB, N: Integer;
  PreA, PreB: String;
begin
  PA := Pos('+', A); if PA > 0 then A := Copy(A, 1, PA - 1);
  PB := Pos('+', B); if PB > 0 then B := Copy(B, 1, PB - 1);
  PreA := ''; PreB := '';
  PA := Pos('-', A); if PA > 0 then begin PreA := Copy(A, PA + 1, Length(A)); A := Copy(A, 1, PA - 1); end;
  PB := Pos('-', B); if PB > 0 then begin PreB := Copy(B, PB + 1, Length(B)); B := Copy(B, 1, PB - 1); end;
  for N := 0 to 2 do
  begin
    Result := VersionPart(A, N) - VersionPart(B, N);
    if Result <> 0 then Exit;
  end;
  if (PreA = '') and (PreB <> '') then Result := 1
  else if (PreA <> '') and (PreB = '') then Result := -1
  else Result := 0;
end;

{ ---------------------------------------------------------------------------------------- }
{ Screens (modules) page                                                                   }
{ ---------------------------------------------------------------------------------------- }

function ModuleRequested(Id, Requested: String): Boolean;
begin
  Requested := ',' + Lowercase(Trim(Requested)) + ',';
  StringChangeEx(Requested, ' ', '', True);
  StringChangeEx(Requested, ';', ',', True);
  if Requested = ',all,' then Result := True
  else Result := Pos(',' + Id + ',', Requested) > 0;
end;

{ The KADAI_MODULES value: checked screens, "all" or "none". }
function SelectedModules(): String;
var
  I, Count: Integer;
begin
  Result := '';
  Count := 0;
  for I := 0 to GetArrayLength(ModuleIds) - 1 do
    if ModulesList.Checked[I] then
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + ModuleIds[I];
      Count := Count + 1;
    end;
  if Count = GetArrayLength(ModuleIds) then Result := 'all'
  else if Count = 0 then Result := 'none';
end;

function SelectedModuleNames(): String;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to GetArrayLength(ModuleIds) - 1 do
    if ModulesList.Checked[I] then
    begin
      if Result <> '' then Result := Result + ', ';
      Result := Result + CustomMessage('Module_' + ModuleIds[I]);
    end;
end;

procedure ModuleClicked(Sender: TObject);
begin
  if ModulesList.ItemIndex >= 0 then
    ModuleDesc.Caption := CustomMessage('Module_' + ModuleIds[ModulesList.ItemIndex] + '_d')
  else
    ModuleDesc.Caption := CustomMessage('ModulesHint');
end;

procedure ApplyPreset(Shown: String);
var
  I: Integer;
begin
  for I := 0 to GetArrayLength(ModuleIds) - 1 do
    ModulesList.Checked[I] := ModuleRequested(ModuleIds[I], Shown);
  ModuleDesc.Caption := CustomMessage('ModulesHint');
end;

procedure PresetAll(Sender: TObject);
begin
  ApplyPreset('all');
end;

procedure PresetSimple(Sender: TObject);
begin
  ApplyPreset('inventory,customers,reports');
end;

procedure PresetBilling(Sender: TObject);
begin
  ApplyPreset('none');
end;

function AddPresetButton(Caption: String; Left: Integer; Handler: TNotifyEvent): TNewButton;
begin
  Result := TNewButton.Create(ModulesPage);
  Result.Parent := ModulesPage.Surface;
  Result.Caption := Caption;
  Result.Left := Left;
  Result.Top := ModulesPage.SurfaceHeight - ScaleY(25);
  Result.Width := ScaleX(110);
  Result.Height := ScaleY(25);
  Result.OnClick := Handler;
end;

procedure CreateModulesPage();
var
  AlwaysOn: TNewStaticText;
  Requested: String;
  I: Integer;
  B: TNewButton;
begin
  ModulesPage := CreateCustomPage(wpSelectTasks, CustomMessage('ModulesTitle'), CustomMessage('ModulesSubtitle'));

  AlwaysOn := TNewStaticText.Create(ModulesPage);
  AlwaysOn.Parent := ModulesPage.Surface;
  AlwaysOn.AutoSize := False;
  AlwaysOn.WordWrap := True;
  AlwaysOn.Width := ModulesPage.SurfaceWidth;
  AlwaysOn.Height := ScaleY(34);
  AlwaysOn.Font.Style := [fsBold];
  AlwaysOn.ShowAccelChar := False;   { "Products & prices": & is text, not a shortcut mark }
  AlwaysOn.Caption := CustomMessage('ModulesAlwaysOn');

  ModuleDesc := TNewStaticText.Create(ModulesPage);
  ModuleDesc.Parent := ModulesPage.Surface;
  ModuleDesc.AutoSize := False;
  ModuleDesc.WordWrap := True;
  ModuleDesc.Width := ModulesPage.SurfaceWidth;
  ModuleDesc.Height := ScaleY(32);
  ModuleDesc.ShowAccelChar := False;
  ModuleDesc.Top := ModulesPage.SurfaceHeight - ScaleY(25) - ScaleY(8) - ModuleDesc.Height;
  ModuleDesc.Caption := CustomMessage('ModulesHint');

  ModulesList := TNewCheckListBox.Create(ModulesPage);
  ModulesList.Parent := ModulesPage.Surface;
  ModulesList.Top := AlwaysOn.Top + AlwaysOn.Height + ScaleY(4);
  ModulesList.Width := ModulesPage.SurfaceWidth;
  ModulesList.Height := ModuleDesc.Top - ScaleY(6) - ModulesList.Top;
  ModulesList.OnClick := @ModuleClicked;
  ModulesList.OnClickCheck := @ModuleClicked;

  Requested := ExpandConstant('{param:MODULES|all}');
  for I := 0 to GetArrayLength(ModuleIds) - 1 do
    ModulesList.AddCheckBox(CustomMessage('Module_' + ModuleIds[I]), '', 0,
      ModuleRequested(ModuleIds[I], Requested), True, False, False, nil);

  B := AddPresetButton(CustomMessage('ModulesPresetAll'), 0, @PresetAll);
  B := AddPresetButton(CustomMessage('ModulesPresetSimple'), ScaleX(118), @PresetSimple);
  B := AddPresetButton(CustomMessage('ModulesPresetBilling'), ScaleX(236), @PresetBilling);
end;

{ ---------------------------------------------------------------------------------------- }
{ Wizard                                                                                   }
{ ---------------------------------------------------------------------------------------- }

function InitializeSetup(): Boolean;
var
  Cmp: Integer;
begin
  Result := True;
  InitModuleIds();
  if FileExists(EnvFilePath()) then
  begin
    InstalledVersion := ReadEnvValue('KADAI_VERSION');
    if RegKeyExists(HKLM, KadaiServiceKey) then
    begin
      Cmp := CompareVersion(InstalledVersion, '{#AppVersion}');
      if Cmp > 0 then
      begin
        SuppressibleMsgBox(FmtMessage(CustomMessage('Downgrade'), [InstalledVersion, '{#AppVersion}']),
          mbCriticalError, MB_OK, IDOK);
        Log('Refusing to downgrade Kadai ' + InstalledVersion + ' to {#AppVersion}');
        Result := False;
        Exit;
      end;
      if Cmp = 0 then Mode := 'Repair' else Mode := 'Upgrade';
    end
    else
      Mode := 'Reinstall';
  end
  else
    Mode := 'Install';
  NeedPgPassword := (Mode = 'Install') and RegKeyExists(HKLM, PgServiceKey) and
    not FileExists(DataRoot() + '\secrets\postgres-superuser.txt');
  Log('Kadai setup mode: ' + Mode + ' (installed: ' + InstalledVersion + ')');
end;

procedure InitializeWizard();
var
  PgFile: String;
  PgSecret: AnsiString;
begin
  CreateModulesPage();

  PortPage := CreateInputQueryPage(ModulesPage.ID, CustomMessage('PortTitle'),
    CustomMessage('PortSubtitle'), CustomMessage('PortText'));
  PortPage.Add(CustomMessage('PortLabel'), False);
  PortPage.Values[0] := ExpandConstant('{param:PORT|8080}');

  PgPage := CreateInputQueryPage(PortPage.ID, CustomMessage('PgTitle'),
    CustomMessage('PgSubtitle'), CustomMessage('PgText'));
  PgPage.Add(CustomMessage('PgLabel'), True);
  PgPage.Values[0] := ExpandConstant('{param:PGPASSWORD|}');
  PgFile := ExpandConstant('{param:PGPASSWORDFILE|}');
  if (PgFile <> '') and LoadStringFromFile(PgFile, PgSecret) then
    PgPage.Values[0] := Trim(PgSecret);

  ProgressPage := CreateOutputProgressPage(CustomMessage('ProgressTitle'), CustomMessage('ProgressSubtitle'));
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if (PageID = ModulesPage.ID) or (PageID = PortPage.ID) then Result := Mode <> 'Install';
  if PageID = PgPage.ID then Result := not NeedPgPassword;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  // Inno Setup calls this in silent installs too: a message box there would wait forever for
  // a click nobody can make. PrepareToInstall checks the same things silently (exit code 7).
  if WizardSilent() then Exit;
  if CurPageID = PortPage.ID then
  begin
    if not ValidPort(PortPage.Values[0]) then
    begin
      MsgBox(CustomMessage('PortInvalid'), mbError, MB_OK);
      Result := False;
    end
    else if PortInUse(Trim(PortPage.Values[0])) then
    begin
      MsgBox(FmtMessage(CustomMessage('PortInUse'), [Trim(PortPage.Values[0])]), mbError, MB_OK);
      Result := False;
    end;
  end;
  if (CurPageID = PgPage.ID) and (Trim(PgPage.Values[0]) = '') then
  begin
    MsgBox(CustomMessage('PgMissing'), mbError, MB_OK);
    Result := False;
  end;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
var
  Screens: String;
begin
  if Mode = 'Upgrade' then
    Result := FmtMessage(CustomMessage('ReadyUpgrade'), [InstalledVersion, '{#AppVersion}'])
  else if Mode = 'Repair' then
    Result := FmtMessage(CustomMessage('ReadyRepair'), ['{#AppVersion}'])
  else if Mode = 'Reinstall' then
    Result := FmtMessage(CustomMessage('ReadyReinstall'), ['{#AppVersion}', DataRoot()])
  else
  begin
    Result := FmtMessage(CustomMessage('ReadyInstall'), ['{#AppVersion}']) + NewLine + NewLine +
      CustomMessage('ReadyAddress') + NewLine + Space + 'http://' + Lowercase(GetComputerNameString()) + ':' + GetPort('');
    Screens := SelectedModules();
    if Screens = 'all' then Screens := CustomMessage('ReadyAllScreens')
    else if Screens = 'none' then Screens := CustomMessage('ModulesPresetBilling')
    else Screens := SelectedModuleNames();
    Result := Result + NewLine + NewLine + CustomMessage('ReadyScreens') + NewLine + Space + Screens;
  end;
  if MemoTasksInfo <> '' then Result := Result + NewLine + NewLine + MemoTasksInfo;
  Result := Result + NewLine + NewLine + FmtMessage(CustomMessage('ReadyFolders'), [ExpandConstant('{app}'), DataRoot()]);
end;

{ ---------------------------------------------------------------------------------------- }
{ Installation with friendly progress                                                      }
{ ---------------------------------------------------------------------------------------- }

{ Maps a "[kadai] ..." line of install.ps1 to a progress step (-1: no step). }
function StepOf(Line: String): Integer;
var
  L: String;
begin
  L := Lowercase(Line);
  Result := -1;
  if Pos('checksum ok', L) > 0 then Result := 1
  else if Pos('unpacked', L) > 0 then Result := 2
  else if Pos('node.js', L) > 0 then Result := 3
  else if Pos('postgresql', L) > 0 then Result := 4
  else if Pos('runtime role', L) > 0 then Result := 5
  else if Pos('pre-upgrade backup', L) > 0 then Result := 6
  else if Pos('windows service', L) > 0 then Result := 7
  else if Pos('firewall', L) > 0 then Result := 8
  else if Pos('scheduled task', L) > 0 then Result := 9
  else if Pos('waiting for', L) > 0 then Result := 10
  else if (Pos('is ready', L) > 0) or (Pos('complete', L) > 0) then Result := 11;
end;

function StepKey(Step: Integer): String;
begin
  case Step of
    1: Result := 'Step_checksum';
    2: Result := 'Step_unpack';
    3: Result := 'Step_node';
    4: Result := 'Step_postgres';
    5: Result := 'Step_database';
    6: Result := 'Step_backup';
    7: Result := 'Step_service';
    8: Result := 'Step_firewall';
    9: Result := 'Step_task';
    10: Result := 'Step_waiting';
    11: Result := 'Step_ready';
  else
    Result := 'Step_start';
  end;
end;

{ Highest step reached so far and the latest raw line, from the install log. }
procedure ReadProgress(var Step: Integer; var LastLine: String; var LastError: String);
var
  Lines: TArrayOfString;
  I, S: Integer;
  L: String;
begin
  if not LoadStringsFromFile(InstallLog, Lines) then Exit;
  for I := 0 to GetArrayLength(Lines) - 1 do
  begin
    L := Trim(Lines[I]);
    if Pos('[kadai] ', L) = 1 then
    begin
      L := Copy(L, 9, Length(L));
      LastLine := L;
      if Pos('ERROR:', L) = 1 then LastError := Trim(Copy(L, 7, Length(L)));
      S := StepOf(L);
      if S > Step then Step := S;
    end;
  end;
end;

procedure ReadSummary(FileName: String);
var
  Lines: TArrayOfString;
  I, N: Integer;
begin
  SetArrayLength(LanUrls, 0);
  if not LoadStringsFromFile(FileName, Lines) then Exit;
  N := 0;
  for I := 0 to GetArrayLength(Lines) - 1 do
    if Pos('URL=', Lines[I]) = 1 then
    begin
      SetArrayLength(LanUrls, N + 1);
      LanUrls[N] := Trim(Copy(Lines[I], 5, Length(Lines[I])));
      N := N + 1;
    end;
end;

function FailWith(Reason: String): String;
var
  RC: Integer;
begin
  Result := CustomMessage('FailTitle') + ': ' + Reason + #13#10#13#10 +
    FmtMessage(CustomMessage('FailLog'), [InstallLog]) + #13#10 + CustomMessage('FailNext');
  Log('Kadai installation failed: ' + Reason);
  if (not WizardSilent()) and FileExists(InstallLog) then
    if MsgBox(Result + #13#10#13#10 + CustomMessage('FailOpenLog'), mbError, MB_YESNO) = IDYES then
      ShellExec('open', 'notepad.exe', Quote(InstallLog), '', SW_SHOWNORMAL, ewNoWait, RC);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Params, KitDir, DepsDir, ExitFile, StartedFile, SummaryFile, SecretFile, LastLine, LastError, Detail: String;
  ExitText: AnsiString;
  RC, Ticks, Step, StepTicks, PrevStep, Position, Secs: Integer;
begin
  Result := '';
  InstallLog := DataRoot() + '\logs\install-' + GetDateTimeString('yyyymmdd-hhnnss', '-', '-') + '.log';
  if Mode = 'Install' then
  begin
    if not ValidPort(GetPort('')) then
    begin
      Result := FmtMessage(CustomMessage('FailPortParam'), [GetPort('')]);
      Exit;
    end;
    if WizardSilent() and PortInUse(GetPort('')) then
    begin
      Result := FmtMessage(CustomMessage('PortInUse'), [GetPort('')]);
      Exit;
    end;
  end;
  if NeedPgPassword and (Trim(PgPage.Values[0]) = '') then
  begin
    Result := CustomMessage('FailNeedPg');
    Exit;
  end;

  if not WizardSilent() then
  begin
    ProgressPage.SetText(CustomMessage('Step_start'), '');
    ProgressPage.SetProgress(0, 1000);
    ProgressPage.Show();
  end;
  try
    ExtractTemporaryFiles('{tmp}\kit\windows\*');
    ExtractTemporaryFiles('{tmp}\deps\*');

    KitDir := ExpandConstant('{tmp}\kit\windows');
    DepsDir := ExpandConstant('{tmp}\deps');
    ExitFile := ExpandConstant('{tmp}\kadai-exit-code.txt');
    StartedFile := ExpandConstant('{tmp}\kadai-started.txt');
    SummaryFile := ExpandConstant('{tmp}\kadai-summary.txt');
    Log('Kadai install log: ' + InstallLog);

    Params := '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File ' + Quote(KitDir + '\run-install.ps1') +
      ' -LogFile ' + Quote(InstallLog) +
      ' -ExitCodeFile ' + Quote(ExitFile) +
      ' -StartedFile ' + Quote(StartedFile) +
      ' -SummaryFile ' + Quote(SummaryFile) +
      ' -InstallDir ' + Quote(ExpandConstant('{app}')) +
      ' -BundlePath ' + Quote(DepsDir + '\{#BundleName}') +
      ' -NodeZip ' + Quote(DepsDir + '\{#NodeZipName}');
    if (Mode = 'Upgrade') or (Mode = 'Repair') then
      Params := Params + ' -Mode Upgrade'
    else
    begin
      Params := Params + ' -Mode ' + Mode +
        ' -PostgresInstaller ' + Quote(DepsDir + '\{#PgInstallerName}') +
        ' -WinSWExe ' + Quote(DepsDir + '\{#WinSWName}') +
        ' -NoShortcut';   { the shortcuts are Setup's own [Icons] }
      if Mode = 'Install' then
        Params := Params + ' -Port ' + GetPort('') + ' -Modules ' + SelectedModules();
      if WizardIsTaskSelected('network') then Params := Params + ' -SetNetworkPrivate';
      if WizardIsTaskSelected('backup') then Params := Params + ' -BackupTask';
    end;
    if NeedPgPassword then
    begin
      // The temporary folder is private to this administrator; run-install.ps1 deletes the
      // file as soon as it has read it.
      SecretFile := ExpandConstant('{tmp}\pg-superuser.txt');
      if not SaveStringToFile(SecretFile, Trim(PgPage.Values[0]), False) then
      begin
        Result := FmtMessage(CustomMessage('FailTemp'), [ExpandConstant('{tmp}')]);
        Exit;
      end;
      Params := Params + ' -PgSecretFile ' + Quote(SecretFile);
    end;

    if not Exec(PowerShellExe(), Params, KitDir, SW_HIDE, ewNoWait, RC) then
    begin
      Result := FmtMessage(CustomMessage('FailStart'), [SysErrorMessage(RC)]);
      Exit;
    end;

    // Poll every 0.5 s: friendly step, a bar that keeps moving inside a step, elapsed time.
    Ticks := 0;
    Step := 0;
    PrevStep := 0;
    StepTicks := 0;
    LastLine := '';
    LastError := '';
    while not FileExists(ExitFile) do
    begin
      Sleep(500);
      Ticks := Ticks + 1;
      if not WizardSilent() then
      begin
        ReadProgress(Step, LastLine, LastError);
        if Step <> PrevStep then
        begin
          PrevStep := Step;
          StepTicks := 0;
        end
        else
          StepTicks := StepTicks + 1;
        Position := Step * 1000 div (StepLast + 1);
        if StepTicks < 140 then
          Position := Position + StepTicks * (1000 div (StepLast + 1) - 10) div 140
        else
          Position := Position + 1000 div (StepLast + 1) - 10;
        Secs := Ticks div 2;
        Detail := FmtMessage(CustomMessage('ProgressElapsed'), [Format('%d:%.2d', [Secs div 60, Secs mod 60])]);
        if LastLine <> '' then Detail := Detail + '   -   ' + LastLine;
        ProgressPage.SetText(CustomMessage(StepKey(Step)), Detail);
        ProgressPage.SetProgress(Position, 1000);
      end;
      // PowerShell refused to run the script (policy, broken install, bad argument): it then
      // never writes the exit code, so do not wait for the full timeout.
      if (Ticks > 240) and not FileExists(StartedFile) and not FileExists(ExitFile) then
      begin
        Result := FailWith(FmtMessage(CustomMessage('FailStart'), ['run-install.ps1 did not start']));
        Exit;
      end;
      if Ticks > InstallTimeoutSeconds * 2 then
      begin
        Result := FailWith(FmtMessage(CustomMessage('FailTimeout'), [IntToStr(InstallTimeoutSeconds div 60)]));
        Exit;
      end;
    end;

    Sleep(500);
    if not LoadStringFromFile(ExitFile, ExitText) then ExitText := '1';
    if Trim(ExitText) <> '0' then
    begin
      Step := 0;
      ReadProgress(Step, LastLine, LastError);
      if LastError = '' then LastError := LastLine;
      Result := FailWith(LastError);
      Exit;
    end;
    if not WizardSilent() then
    begin
      ProgressPage.SetText(CustomMessage('Step_ready'), '');
      ProgressPage.SetProgress(1000, 1000);
    end;
    ReadSummary(SummaryFile);
    Log('Kadai installation script finished');
  finally
    if not WizardSilent() then ProgressPage.Hide();
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  Text: String;
  I: Integer;
begin
  if CurPageID = wpFinished then
  begin
    if Mode = 'Upgrade' then Text := FmtMessage(CustomMessage('FinishUpgraded'), ['{#AppVersion}'])
    else if Mode = 'Repair' then Text := CustomMessage('FinishRepaired')
    else Text := CustomMessage('FinishInstalled');
    Text := Text + #13#10#13#10 + FmtMessage(CustomMessage('FinishThisPc'), [GetPort('')]);
    if GetArrayLength(LanUrls) > 0 then
    begin
      Text := Text + #13#10#13#10 + CustomMessage('FinishOthers');
      for I := 0 to GetArrayLength(LanUrls) - 1 do
        Text := Text + #13#10 + '      ' + LanUrls[I];
    end;
    if (Mode = 'Install') or (Mode = 'Reinstall') then
      Text := Text + #13#10#13#10 + CustomMessage('FinishFirstRun');
    Text := Text + #13#10#13#10 + FmtMessage(CustomMessage('FinishKeepEnv'), [EnvFilePath()]);
    WizardForm.FinishedLabel.Caption := Text;
    WizardForm.FinishedLabel.AdjustHeight();
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if (CurUninstallStep = usPostUninstall) and not UninstallSilent() then
    MsgBox(FmtMessage(CustomMessage('UninstallKept'), [DataRoot()]), mbInformation, MB_OK);
end;
