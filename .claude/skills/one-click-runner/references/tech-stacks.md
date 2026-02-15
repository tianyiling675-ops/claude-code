# Tech Stack Detection & Windows Portable Setup

## Detection Patterns

### Python
- **Indicators**: `requirements.txt`, `setup.py`, `pyproject.toml`, `Pipfile`, `environment.yml`, `*.py` entry points
- **Entry point detection**: Look for `main.py`, `app.py`, `run.py`, `server.py`, `webui.py`, `launch.py`, or `__main__.py`. Check README for launch commands like `python xxx.py`
- **WebUI detection**: Check for Flask/FastAPI/Gradio/Streamlit/Django in dependencies

### Node.js
- **Indicators**: `package.json`, `yarn.lock`, `pnpm-lock.yaml`, `package-lock.json`
- **Entry point detection**: Check `package.json` → `scripts.start`, `scripts.dev`, or `main` field
- **WebUI detection**: Check for next, nuxt, vite, react, vue, express, koa in dependencies

### Go
- **Indicators**: `go.mod`, `go.sum`, `*.go`
- **Prefer pre-built binaries**: Check GitHub Releases for `*windows*amd64*` assets
- **Entry point**: Usually `main.go` or `cmd/` directory

### Rust
- **Indicators**: `Cargo.toml`, `Cargo.lock`
- **Prefer pre-built binaries**: Check GitHub Releases for `*windows*` or `*x86_64-pc-windows*` assets
- **Entry point**: Defined in `Cargo.toml` `[[bin]]` section

### C/C++
- **Indicators**: `CMakeLists.txt`, `Makefile`, `*.sln`, `*.vcxproj`
- **ALWAYS use pre-built binaries**: Check GitHub Releases first. Building C/C++ on Windows is complex, avoid it
- **Fallback**: If no pre-built binary, document build requirements and use vcpkg/MSYS2

## Windows Portable Runtime Setup

### Embedded Python (Recommended for Python projects)

```bat
@echo off
set PYTHON_VERSION=3.11.9
set PYTHON_DIR=%~dp0runtime\python

if not exist "%PYTHON_DIR%\python.exe" (
    echo Downloading Python %PYTHON_VERSION%...
    curl -L -o python.zip "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
    mkdir "%PYTHON_DIR%" 2>nul
    powershell -Command "Expand-Archive -Path python.zip -DestinationPath '%PYTHON_DIR%' -Force"
    del python.zip

    REM Enable pip in embedded Python
    echo import site>> "%PYTHON_DIR%\python311._pth"
    curl -L -o "%PYTHON_DIR%\get-pip.py" https://bootstrap.pypa.io/get-pip.py
    "%PYTHON_DIR%\python.exe" "%PYTHON_DIR%\get-pip.py"
)
```

**Important notes for embedded Python:**
- Must uncomment `import site` in `python3XX._pth` file to enable pip
- The `._pth` filename matches Python version (e.g. `python311._pth` for 3.11)
- Virtual environments don't work with embedded Python; install packages directly
- Use `"%PYTHON_DIR%\python.exe" -m pip install -r requirements.txt`

### Portable Node.js (Recommended for Node.js projects)

```bat
@echo off
set NODE_VERSION=20.11.1
set NODE_DIR=%~dp0runtime\node

if not exist "%NODE_DIR%\node.exe" (
    echo Downloading Node.js %NODE_VERSION%...
    curl -L -o node.zip "https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip"
    mkdir "%NODE_DIR%" 2>nul
    powershell -Command "Expand-Archive -Path node.zip -DestinationPath '%~dp0runtime\temp' -Force"
    move "%~dp0runtime\temp\node-v%NODE_VERSION%-win-x64\*" "%NODE_DIR%\"
    rmdir /s /q "%~dp0runtime\temp"
    del node.zip
)

set PATH=%NODE_DIR%;%NODE_DIR%\node_modules\.bin;%PATH%
```

**Package manager setup:**
```bat
REM npm (built-in)
call "%NODE_DIR%\npm.cmd" install

REM pnpm (if project uses it)
call "%NODE_DIR%\npm.cmd" install -g pnpm
call "%NODE_DIR%\pnpm.cmd" install

REM yarn (if project uses it)
call "%NODE_DIR%\npm.cmd" install -g yarn
call "%NODE_DIR%\yarn.cmd" install
```

### Git Portable (if project needs git clone)

```bat
set GIT_VERSION=2.44.0
set GIT_DIR=%~dp0runtime\git

if not exist "%GIT_DIR%\cmd\git.exe" (
    echo Downloading Git %GIT_VERSION%...
    curl -L -o git.zip "https://github.com/git-for-windows/git/releases/download/v%GIT_VERSION%.windows.1/MinGit-%GIT_VERSION%-64-bit.zip"
    mkdir "%GIT_DIR%" 2>nul
    powershell -Command "Expand-Archive -Path git.zip -DestinationPath '%GIT_DIR%' -Force"
    del git.zip
)
set PATH=%GIT_DIR%\cmd;%PATH%
```

## GPU/CUDA Considerations

For AI/ML projects requiring CUDA:
- Do NOT try to install CUDA automatically — it requires admin privileges and system restart
- Instead, detect if CUDA is available and provide guidance:

```bat
where nvcc >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] NVIDIA CUDA not detected.
    echo Please install CUDA Toolkit from: https://developer.nvidia.com/cuda-downloads
    echo After installing, restart this script.
    pause
    exit /b 1
)
```

- For PyTorch projects, use the appropriate pip index:
```bat
REM CUDA 12.1
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
REM CPU only
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```
