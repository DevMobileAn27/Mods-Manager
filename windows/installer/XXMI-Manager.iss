#ifndef AppVersion
  #error AppVersion must be passed to ISCC with /DAppVersion=...
#endif
#ifndef WindowsVersion
  #error WindowsVersion must be passed to ISCC with /DWindowsVersion=...
#endif

[Setup]
AppId={{2C5E7E32-1767-4B91-A9E9-4A86D39C654B}
AppName=XXMI Manager
AppVersion={#AppVersion}
VersionInfoVersion={#WindowsVersion}
AppPublisher=DevMobileAn27
DefaultDirName={localappdata}\Programs\XXMI Manager
DefaultGroupName=XXMI Manager
OutputDir=..\..\dist
OutputBaseFilename=XXMI-Manager-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\xxmi_manager.exe
WizardStyle=modern

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\XXMI Manager"; Filename: "{app}\xxmi_manager.exe"
Name: "{autodesktop}\XXMI Manager"; Filename: "{app}\xxmi_manager.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Run]
Filename: "{app}\xxmi_manager.exe"; Description: "Launch XXMI Manager"; Flags: nowait postinstall skipifsilent
