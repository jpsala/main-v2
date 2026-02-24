; Inno Setup script for Main.ahk Automation Tool
; Requires Inno Setup 6.x (https://jrsoftware.org/isinfo.php)
;
; Build: Run build.bat first, then compile this script with Inno Setup.
; The installer reads from the dist/ folder produced by build.bat.

#define MyAppName "Main Automation"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "JP Salazar"
#define MyAppExeName "main.exe"

[Setup]
AppId={{B2C3D4E5-F6A7-8901-BCDE-FG2345678901}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=main-automation-setup
Compression=lzma2
SolidCompression=yes
SetupIconFile=main.ico
UninstallDisplayIcon={app}\main.ico
PrivilegesRequired=lowest
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
english.InstallTypeTitle=Installation Type
english.InstallTypeDesc=Choose how to install Main Automation
english.InstallTypePrompt=An existing installation was detected. Please choose how to proceed:
english.InstallTypeUpgrade=Update (keep your settings and customizations)
english.InstallTypeClean=Clean install (reset everything to defaults)

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startupentry"; Description: "Start with Windows"; GroupDescription: "Other:"

[InstallDelete]
; Delete user files when doing a clean install
Type: files; Name: "{app}\config.ini"; Check: IsCleanInstall

[Files]
; Main executable
Source: "dist\main.exe"; DestDir: "{app}"; Flags: ignoreversion

; UI files
Source: "dist\ui\*"; DestDir: "{app}\ui"; Flags: ignoreversion recursesubdirs createallsubdirs

; Libraries (includes WebView2 DLLs)
Source: "dist\lib\*"; DestDir: "{app}\lib"; Flags: ignoreversion recursesubdirs createallsubdirs

; Icons
Source: "dist\main.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\icon.ico"; DestDir: "{app}"; Flags: ignoreversion

; Config - use uninsneveruninstall to preserve on uninstall, but allow clean install to replace
Source: "dist\config.ini"; DestDir: "{app}"; Flags: ignoreversion; Check: ShouldInstallUserFile('config.ini')

; Documentation
Source: "dist\README.md"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Start with Windows (only if user checked the option)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MainAutomation"; ValueData: """{app}\{#MyAppExeName}"""; Flags: uninsdeletevalue; Tasks: startupentry

[Run]
; Option to launch the app after installation finishes
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
var
  CleanInstall: Boolean;
  InstallTypePage: TInputOptionWizardPage;

function IsAppInstalled: Boolean;
var
  InstallDir: String;
begin
  // Check registry first
  if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#SetupSetting("AppId")}_is1',
    'InstallLocation', InstallDir) and (InstallDir <> '') and DirExists(InstallDir) then
  begin
    Result := True;
    Exit;
  end;
  
  // Check if installation directory exists with key files
  InstallDir := ExpandConstant('{autopf}\{#MyAppName}');
  Result := DirExists(InstallDir) and 
    (FileExists(InstallDir + '\{#MyAppExeName}') or 
     FileExists(InstallDir + '\config.ini'));
end;

function HasUserSettings: Boolean;
var
  InstallDir: String;
begin
  InstallDir := ExpandConstant('{autopf}\{#MyAppName}');
  Result := FileExists(InstallDir + '\config.ini');
end;

function IsCleanInstall: Boolean;
begin
  Result := CleanInstall;
end;

procedure KillRunningApp;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/f /im {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(500);
end;

function ShouldInstallUserFile(FileName: String): Boolean;
begin
  // Clean install: always overwrite. Update install: only if file doesn't exist.
  Result := CleanInstall or not (FileExists(ExpandConstant('{app}\') + FileName) or DirExists(ExpandConstant('{app}\') + FileName));
end;

procedure CleanInstallDir;
var
  InstallDir: String;
  RetryCount: Integer;
begin
  InstallDir := WizardDirValue;
  if not DirExists(InstallDir) then
    Exit;
    
  // Make sure critical user files are deleted even if DelTree fails
  DeleteFile(InstallDir + '\config.ini');
  
  // Try to delete entire directory tree
  RetryCount := 0;
  while (RetryCount < 3) and DirExists(InstallDir) do
  begin
    if DelTree(InstallDir, True, True, True) then
      Break;
    Sleep(500);
    RetryCount := RetryCount + 1;
  end;
  
  // Recreate directory for installation
  if not DirExists(InstallDir) then
    ForceDirectories(InstallDir);
end;

procedure InitializeWizard;
begin
  // Create custom page only if app is already installed
  if IsAppInstalled and HasUserSettings then
  begin
    InstallTypePage := CreateInputOptionPage(wpWelcome,
      ExpandConstant('{cm:InstallTypeTitle}'),
      ExpandConstant('{cm:InstallTypeDesc}'),
      ExpandConstant('{cm:InstallTypePrompt}'),
      True, False);
    
    InstallTypePage.Add(ExpandConstant('{cm:InstallTypeUpgrade}'));
    InstallTypePage.Add(ExpandConstant('{cm:InstallTypeClean}'));
    
    InstallTypePage.SelectedValueIndex := 0; // Default to Update
  end;
end;

function InitializeSetup: Boolean;
begin
  CleanInstall := False;
  Result := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  
  // Process install type selection when leaving the custom page
  if (InstallTypePage <> nil) and (CurPageID = InstallTypePage.ID) then
  begin
    CleanInstall := (InstallTypePage.SelectedValueIndex = 1);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    KillRunningApp;
    if CleanInstall then
    begin
      CleanInstallDir;
    end;
  end;
end;
