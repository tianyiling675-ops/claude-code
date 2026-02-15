---
name: one-click-runner
description: "Create Windows one-click integration packages for GitHub open-source projects. Analyzes a GitHub repository, generates Windows startup scripts (.bat), optional WebUI control panel, and Inno Setup installer script (.iss) for .exe packaging. Use when users want to: (1) make a GitHub project easy to run on Windows, (2) create an integration package (整合包) for a project, (3) generate one-click launchers, (4) package a project as a Windows .exe installer. Triggers on phrases like 做个整合包, one-click, 一键启动, make it easy to run, 打包成exe."
---

# One Click Runner

Create Windows one-click integration packages from GitHub repositories. Turn any open-source project into a double-click-to-run experience.

## Workflow

1. **Analyze** the GitHub repository
2. **Detect** tech stack and dependencies
3. **Create** startup scripts (`start.bat`, `stop.bat`)
4. **Handle WebUI** (use existing or generate control panel)
5. **Create** Inno Setup installer script (`.iss`)
6. **Deliver** the complete package

## Step 1: Analyze Repository

Clone or fetch the repository. Read these files to understand the project:

- `README.md` — Setup instructions, dependencies, launch commands
- Dependency files — `requirements.txt`, `package.json`, `go.mod`, `Cargo.toml`, etc.
- Entry points — `main.py`, `app.py`, `index.js`, `main.go`, etc.
- Existing scripts — `launch.py`, `start.sh`, `docker-compose.yml`, `Makefile`
- GitHub Releases — Check for pre-built Windows binaries

**Determine:**
1. Primary language/framework
2. All dependencies (system-level and package-level)
3. Entry point command(s)
4. Whether the project has a built-in WebUI
5. Whether pre-built Windows binaries are available

For tech stack details, see [references/tech-stacks.md](references/tech-stacks.md).

## Step 2: Create start.bat

Use [assets/start-template.bat](assets/start-template.bat) as the base. The script must:

1. **Set UTF-8 encoding**: `chcp 65001` (for Chinese/Unicode support)
2. **Set working directory**: `cd /d "%~dp0"`
3. **Download/setup portable runtime** (if not present):
   - Python projects → Embedded Python (no install needed)
   - Node.js projects → Portable Node.js
   - Go/Rust/C++ → Use pre-built binaries from GitHub Releases
   - See [references/tech-stacks.md](references/tech-stacks.md) for download URLs and setup commands
4. **Install dependencies** (if not already installed):
   - Python: `python.exe -m pip install -r requirements.txt`
   - Node.js: `npm install` / `pnpm install`
5. **Launch the application**
6. **Open browser** (if WebUI): `start http://localhost:PORT`

**Critical rules for .bat files:**
- Always use `%~dp0` for paths (script's own directory)
- Quote all paths: `"%~dp0runtime\python\python.exe"`
- Use `if not exist` to skip already-completed steps
- Show clear progress messages with `echo`
- Handle errors with `if %errorlevel% neq 0`
- End with `pause` so the user can see any errors

Also create a `stop.bat` that kills the running process.

## Step 3: Handle WebUI

**Decision tree:**

1. **Project has built-in WebUI** (Flask, Gradio, Streamlit, Next.js, etc.)
   → Use it directly. Ensure `start.bat` opens the correct URL.

2. **Project is CLI-only**
   → Generate a Gradio-based control panel. See [references/webui-generation.md](references/webui-generation.md).
   → The control panel provides: Start/Stop buttons, log viewer, basic configuration.
   → Install `gradio` as an additional dependency.

3. **Project processes files** (image tools, converters, etc.)
   → Generate a Gradio UI with file upload/download widgets.

## Step 4: Create Inno Setup Installer Script

Use [assets/installer-template.iss](assets/installer-template.iss) as the base. Customize:

- `AppName`, `AppVersion`, `OutputBaseFilename`
- `[Files]` section to include all necessary project files
- `[Icons]` for Start Menu and Desktop shortcuts
- `PrivilegesRequired=lowest` for no-admin install

See [references/inno-setup.md](references/inno-setup.md) for full guide.

## Step 5: Deliver

Create the complete package directory:

```
{project-name}-package/
├── start.bat                 ← Double-click to launch
├── stop.bat                  ← Stop the running application
├── installer.iss             ← Compile with Inno Setup for .exe
├── project/                  ← Project source code
│   └── ...
├── webui.py                  ← Generated control panel (if needed)
└── assets/
    └── icon.ico              ← App icon (if available)
```

Provide the user with:
1. The complete package directory
2. Instructions: "To create the .exe installer, install [Inno Setup](https://jrsoftware.org/isdl.php), then right-click `installer.iss` → Compile"
3. Note: "Or just double-click `start.bat` to run directly without installing"

## Output Language

Match the language of all user-facing text (echo messages in .bat, UI labels) to the user's language. If the user speaks Chinese, all prompts and messages should be in Chinese.
