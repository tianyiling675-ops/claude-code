; MetaGPT 一键整合包 - Inno Setup 安装脚本
; 编译方法: 安装 Inno Setup (https://jrsoftware.org/isdl.php)
; 然后右键此文件 -> Compile 或命令行运行: iscc installer.iss

[Setup]
AppName=MetaGPT
AppVersion=1.0
AppPublisher=MetaGPT Community
AppURL=https://github.com/FoundationAgents/MetaGPT
DefaultDirName={autopf}\MetaGPT
DefaultGroupName=MetaGPT
OutputBaseFilename=MetaGPT-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
LicenseFile=
; SetupIconFile=assets\icon.ico

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; 启动脚本
Source: "start.bat"; DestDir: "{app}"
Source: "stop.bat"; DestDir: "{app}"
Source: "webui.py"; DestDir: "{app}"
; 运行时环境（如果已预下载的话）
; Source: "runtime\*"; DestDir: "{app}\runtime"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MetaGPT"; Filename: "{app}\start.bat"; Comment: "启动 MetaGPT"
Name: "{group}\停止 MetaGPT"; Filename: "{app}\stop.bat"; Comment: "停止 MetaGPT"
Name: "{group}\卸载 MetaGPT"; Filename: "{uninstallexe}"
Name: "{commondesktop}\MetaGPT"; Filename: "{app}\start.bat"; Tasks: desktopicon; Comment: "启动 MetaGPT"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式:"; Flags: checked

[Run]
Filename: "{app}\start.bat"; Description: "立即启动 MetaGPT"; Flags: postinstall nowait skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\runtime"
Type: filesandordirs; Name: "{app}\workspace"
Type: filesandordirs; Name: "{app}\__pycache__"
