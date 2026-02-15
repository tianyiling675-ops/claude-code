# Inno Setup Packaging Guide

Inno Setup creates professional Windows `.exe` installers. It's free, widely used, and produces reliable installers.

## How It Works

1. Write an `.iss` script (plain text) describing what to install and where
2. Compile with Inno Setup Compiler (`iscc`) → produces a single `.exe`
3. User double-clicks the `.exe` → standard Windows installer wizard

## Template `.iss` Script

```iss
; Inno Setup Script for {PROJECT_NAME}
; Compile with: iscc installer.iss

[Setup]
AppName={PROJECT_NAME}
AppVersion=1.0
DefaultDirName={autopf}\{PROJECT_NAME}
DefaultGroupName={PROJECT_NAME}
OutputBaseFilename={PROJECT_NAME}-Setup
Compression=lzma2
SolidCompression=yes
SetupIconFile=assets\icon.ico
; Uncomment below for no admin required (installs to user folder)
; PrivilegesRequired=lowest

[Files]
; Include all project files
Source: "project\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs
; Include portable runtime
Source: "runtime\*"; DestDir: "{app}\runtime"; Flags: recursesubdirs createallsubdirs
; Include launcher scripts
Source: "start.bat"; DestDir: "{app}"
Source: "stop.bat"; DestDir: "{app}"

[Icons]
; Start menu shortcut
Name: "{group}\{PROJECT_NAME}"; Filename: "{app}\start.bat"; IconFilename: "{app}\assets\icon.ico"
; Desktop shortcut
Name: "{commondesktop}\{PROJECT_NAME}"; Filename: "{app}\start.bat"; IconFilename: "{app}\assets\icon.ico"
; Uninstaller in start menu
Name: "{group}\Uninstall {PROJECT_NAME}"; Filename: "{uninstallexe}"

[Run]
; Run after install (optional)
Filename: "{app}\start.bat"; Description: "Launch {PROJECT_NAME}"; Flags: postinstall nowait skipifsilent

[UninstallDelete]
; Clean up runtime and cache on uninstall
Type: filesandordirs; Name: "{app}\runtime"
Type: filesandordirs; Name: "{app}\__pycache__"
Type: filesandordirs; Name: "{app}\node_modules"
```

## Key Sections Explained

| Section | Purpose |
|---------|---------|
| `[Setup]` | Installer metadata, output filename, compression |
| `[Files]` | What files to include and where to install them |
| `[Icons]` | Start menu and desktop shortcuts |
| `[Run]` | Commands to run after installation |
| `[UninstallDelete]` | Extra cleanup on uninstall |

## Compiling

User needs Inno Setup installed on Windows:
- Download: https://jrsoftware.org/isdl.php
- Command line: `iscc installer.iss`
- GUI: Open `.iss` file in Inno Setup Compiler → Build → Compile

## Directory Structure Before Compilation

```
package/
├── installer.iss          ← Inno Setup script
├── start.bat              ← Launcher
├── stop.bat               ← Stopper
├── project/               ← Project source code
│   └── (all project files)
├── runtime/               ← Portable runtimes (downloaded on first run or pre-bundled)
│   ├── python/            ← Embedded Python (optional)
│   └── node/              ← Portable Node.js (optional)
└── assets/
    └── icon.ico           ← Application icon
```

## Tips

- **File size**: Inno Setup handles large packages well (up to 2GB+)
- **No admin**: Set `PrivilegesRequired=lowest` for user-level install (no admin prompt)
- **Silent install**: Users can run `Setup.exe /SILENT` for unattended install
- **Icon**: Generate a `.ico` file or use a default one; 256x256 PNG converted to ICO works
- **Pre-bundling runtimes**: For a true one-click experience, download Python/Node.js portable and include in `runtime/` before compiling. This makes the installer larger but requires no internet on the target machine
