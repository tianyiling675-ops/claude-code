; Inno Setup Script for {PROJECT_NAME}
; Compile: iscc installer.iss
; Download Inno Setup: https://jrsoftware.org/isdl.php

[Setup]
AppName={PROJECT_NAME}
AppVersion={VERSION}
AppPublisher={PROJECT_NAME}
DefaultDirName={autopf}\{PROJECT_NAME}
DefaultGroupName={PROJECT_NAME}
OutputBaseFilename={PROJECT_NAME}-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
; SetupIconFile=assets\icon.ico

[Files]
Source: "project\*"; DestDir: "{app}\project"; Flags: recursesubdirs createallsubdirs
Source: "start.bat"; DestDir: "{app}"
Source: "stop.bat"; DestDir: "{app}"
; Uncomment if bundling portable runtime:
; Source: "runtime\*"; DestDir: "{app}\runtime"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{PROJECT_NAME}"; Filename: "{app}\start.bat"
Name: "{commondesktop}\{PROJECT_NAME}"; Filename: "{app}\start.bat"; Tasks: desktopicon
Name: "{group}\Uninstall {PROJECT_NAME}"; Filename: "{uninstallexe}"

[Tasks]
Name: "desktopicon"; Description: "Create desktop shortcut"; GroupDescription: "Shortcuts:"

[Run]
Filename: "{app}\start.bat"; Description: "Launch {PROJECT_NAME} now"; Flags: postinstall nowait skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\runtime"
Type: filesandordirs; Name: "{app}\__pycache__"
Type: filesandordirs; Name: "{app}\node_modules"
Type: filesandordirs; Name: "{app}\.venv"
