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

**CRITICAL: Use Python 3.10 (not 3.11+) for best wheel compatibility.** Many packages (e.g. pandas pinned versions) only have pre-built wheels for 3.10. Python 3.11+ forces source builds that fail without MSVC.

**CRITICAL: Use `goto` flow control, NOT `if ( )` blocks.** Chinese/UTF-8 characters inside `( )` blocks corrupt Windows CMD parsing. Always use `if ... goto label` pattern.

**CRITICAL: Use `uv` instead of `pip` for complex projects.** pip's dependency resolver fails (`resolution-too-deep`) on projects with 50+ pinned dependencies. Download standalone `uv.exe` from GitHub releases.

```bat
@echo off
set PYTHON_VERSION=3.10.11
set PYTHON_DIR=%~dp0runtime\python
set PYTHON_EXE=%PYTHON_DIR%\python.exe
set PTH_FILE=%PYTHON_DIR%\python310._pth

if exist "%PYTHON_EXE%" goto python_ok
echo Downloading Python %PYTHON_VERSION%...
curl -L -o "%~dp0runtime\python.zip" "https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
mkdir "%PYTHON_DIR%" 2>nul
powershell -Command "Expand-Archive -Path '%~dp0runtime\python.zip' -DestinationPath '%PYTHON_DIR%' -Force"
del "%~dp0runtime\python.zip" 2>nul

REM Enable pip (only append once)
findstr /c:"import site" "%PTH_FILE%" >nul 2>&1
if !errorlevel! neq 0 echo import site>> "%PTH_FILE%"
curl -sL -o "%PYTHON_DIR%\get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
"%PYTHON_EXE%" "%PYTHON_DIR%\get-pip.py" --quiet
del "%PYTHON_DIR%\get-pip.py" 2>nul

REM MUST install setuptools (provides pkg_resources needed by many setup.py)
"%PYTHON_EXE%" -m pip install setuptools wheel --quiet
:python_ok
```

**Important notes for embedded Python:**
- Use Python 3.10.x for maximum pre-built wheel availability
- Must add `import site` to `python3XX._pth` file to enable pip (use `findstr` to avoid duplicates)
- The `._pth` filename matches Python version (e.g. `python310._pth` for 3.10)
- ALWAYS install `setuptools` and `wheel` after pip — embedded Python lacks them and many packages need `pkg_resources` for building
- Virtual environments don't work with embedded Python; install packages directly
- Use `uv pip install <pkg> --python "%PYTHON_EXE%"` for complex dependency resolution, fallback to pip

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
