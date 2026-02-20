---
name: github-integrator
description: 为 GitHub 开源项目生成 Windows 一键整合包，包含自动安装脚本和 WebUI 前端。当用户发来 GitHub 链接并说"帮我做个整合包"时触发此 Skill。
---

# GitHub 项目整合包生成器

## 你的任务

用户是编程小白，他们喜欢体验开源项目，但搞不定各种环境和命令。你的任务是：

1. 读取用户发来的 GitHub 项目
2. 理解这个项目是干什么的、怎么运行的
3. 判断项目本身是否自带 WebUI
4. 生成一个 **Windows 一键整合包**：
   - **如果项目自带 WebUI**：只需生成 `install_and_run.bat`，直接启动项目自身的 Web 服务
   - **如果项目不自带 WebUI**：生成 `install_and_run.bat` + `webui.py`（用 Gradio 或 Streamlit 包装）

交付给用户的东西要让他们**不需要懂任何命令行**，下载下来双击就能跑。

---

## 第一步：分析项目

用户发来 GitHub 链接后，你需要先搞清楚这个项目的基本情况：

**必须确认的信息：**

- 项目用什么语言写的？（Python / Node.js / 其他）
- 依赖怎么管理的？（pip + requirements.txt / conda / npm / 其他）
- 项目的入口是什么？（哪个文件、哪个命令可以启动它）
- **项目本身是不是已经自带 WebUI？**（比如 open-webui、Lobe Chat、ChatGPT-Next-Web 这类项目本身就是网页界面，不需要再包一层 Gradio/Streamlit）
- 如果不自带 WebUI，项目有没有提供 API 或者函数接口？（决定怎么包装界面）
- **项目对 Python 版本有没有硬性要求？**（有些项目只支持特定版本，比如 open-webui 要求 Python 3.11，不能高也不能低）
- **项目安装后是否需要用户额外配置才能使用？**（比如填 API Key、连接本地模型等）

**分析方法：**

- 优先读 README.md，找"Installation"和"Usage"部分
- 查看根目录是否有 `requirements.txt`、`setup.py`、`pyproject.toml`、`package.json` 等文件
- 找主入口文件（通常是 `main.py`、`app.py`、`cli.py` 等）

如果用户只发了链接，你需要通过 fetch 工具去读取 GitHub 页面或原始文件内容。

---

## 第二步：判断项目类型，选择打包方案

### 类型 A0：自带 WebUI 的项目（优先判断！）

**条件**：项目本身就是一个 Web 应用 / WebUI，比如：
- open-webui（AI 对话平台，自带网页界面）
- Lobe Chat、ChatGPT-Next-Web 等聊天界面项目
- 任何 `pip install xxx` 后用 `xxx serve` 或 `xxx start` 就能在浏览器里用的项目
- 项目 README 里提到 "visit http://localhost:xxxx" 之类的

**关键原则：不要再套一层 Gradio/Streamlit！项目本身就是 WebUI，多包一层纯属多余。**

**打包方案**：

`install_and_run.bat` 只需要做：

1. 检查并安装指定版本的 Python
2. 创建虚拟环境 + 安装项目
3. 打印使用引导（如果项目启动后还需要配置）
4. 用 `start http://localhost:端口号` 打开浏览器
5. 执行项目自身的启动命令

**不需要生成 `webui.py`，只需要一个 bat 文件。**

### 类型 A：普通 Python 项目

**条件**：有 `requirements.txt` 或 `setup.py`，主文件是 `.py`，且项目本身**不自带 WebUI**

**打包方案**：

`install_and_run.bat` 做以下事情：

1. 检查指定版本的 Python 是否已安装（见下方"Python 版本锁定"）
2. 创建虚拟环境
3. 激活虚拟环境
4. 安装依赖（`pip install -r requirements.txt`）
5. 启动 WebUI（`python webui.py`）

**WebUI 框架选择规则**（自动判断）：

- 项目是 AI / 机器学习 / 图像处理 / 文本生成类 → 用 **Gradio**（原生支持这类交互，零配置）
- 项目是数据分析 / 展示图表 / 多页应用 / 通用工具 → 用 **Streamlit**（布局更灵活）
- 无法判断时默认用 **Gradio**（安装更轻量）

`webui.py` 包装逻辑：

- 如果原项目有可调用的 Python 函数，直接导入并包一层界面
- 如果原项目是命令行工具，用 `subprocess` 调用并在界面里展示输出

### Python 版本锁定（重要！）

很多项目对 Python 版本有严格要求。**必须在分析阶段确认项目需要的 Python 版本**，然后在 bat 脚本里锁定。

**检测逻辑（按优先级）：**

1. 优先使用 `py -X.Y`（Windows Python Launcher，天然支持多版本共存）
2. fallback 检查 `python --version` 输出是否匹配目标版本
3. 都没有 → 用 `winget install Python.Python.X.Y` 安装**指定版本**

**千万不要用 `winget install Python.Python.3`（不指定小版本）！** 这会装最新版，可能和项目不兼容。

示例（锁定 Python 3.11）：

```bat
set "PYTHON_CMD="

:: 优先尝试 py launcher
py -3.11 --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=py -3.11"
    goto :python_ok
)

:: fallback：检查 python 命令是否为目标版本
for /f "tokens=2 delims= " %%v in ('python --version 2^>nul') do (
    echo %%v | findstr /b "3.11" >nul
    if not errorlevel 1 (
        set "PYTHON_CMD=python"
        goto :python_ok
    )
)

:: 自动安装指定版本
winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements
```

后续统一用 `%PYTHON_CMD%` 代替 `python`：

```bat
%PYTHON_CMD% -m venv venv
```

### 类型 B：Node.js 项目

**条件**：有 `package.json`

**打包方案**：

`install_and_run.bat` 做以下事情：

1. 检查 Node.js 是否已安装
2. 运行 `npm install`
3. 运行 `npm start` 或对应启动命令

WebUI：如果项目本身是 web 服务，直接在 bat 里启动后提示用户打开浏览器；如果是纯 CLI 工具，用 Python + Gradio 包一层。

### 类型 C：无法自动化的项目

**条件**：需要 Docker、需要 GPU 驱动、依赖太复杂、不是 Python/Node

**处理方式**：

- 诚实告诉用户这个项目比较复杂，无法做到真正一键安装
- 给出一份尽量简单的"人工操作指南"，用大白话写，每一步说清楚干什么
- 如果部分可以自动化，尽量自动化那部分

---

## 第三步：生成文件

### 文件编码（极其重要！）

**bat 文件必须用 GBK 编码保存，不能用 UTF-8！**

- 中文 Windows 默认编码是 GBK（代码页 936），bat 文件会按系统默认编码读取
- 如果 bat 文件是 UTF-8 编码，所有中文 echo 会变成乱码并可能报错
- **不要加 `chcp 65001`**，这行在 bat 文件自身编码不对时也救不了
- 生成文件后，必须用 `iconv -f UTF-8 -t GBK` 转码：

```bash
iconv -f UTF-8 -t GBK install_and_run.bat > install_and_run_gbk.bat
mv install_and_run_gbk.bat install_and_run.bat
```

### `install_and_run.bat` 模板（普通 Python 项目，需要 WebUI 包装）

```bat
@echo off
title 项目启动器

echo ========================================
echo  欢迎使用！正在为您自动安装和启动...
echo ========================================
echo.

:: ---- Python 版本检测（根据项目需求替换版本号）----
set "PYTHON_CMD="
set "PY_VER=3.11"

py -%PY_VER% --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=py -%PY_VER%"
    goto :python_ok
)

for /f "tokens=2 delims= " %%v in ('python --version 2^>nul') do (
    echo %%v | findstr /b "%PY_VER%" >nul
    if not errorlevel 1 (
        set "PYTHON_CMD=python"
        goto :python_ok
    )
)

echo [提示] 未检测到 Python %PY_VER%，正在为您自动安装...
echo        这需要大约 1-2 分钟，请耐心等待。
echo.
winget install -e --id Python.Python.%PY_VER% --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
    echo.
    echo [错误] 自动安装 Python %PY_VER% 失败。
    echo 请手动去这里下载安装：https://www.python.org/downloads/
    echo 安装时记得勾选最下面那个 "Add Python to PATH" 选项！
    echo 安装完成后，重新双击本程序即可。
    pause
    exit /b 1
)
echo.
echo [完成] Python %PY_VER% 安装成功！
echo        请关闭此窗口，然后重新双击本程序启动。
pause
exit /b 0

:python_ok
echo [√] 已检测到 Python %PY_VER%
echo.

:: ---- 创建虚拟环境 ----
if not exist "venv" (
    echo [1/3] 正在创建专属运行环境...
    %PYTHON_CMD% -m venv venv
    if errorlevel 1 (
        echo.
        echo [错误] 创建虚拟环境失败，请检查 Python %PY_VER% 是否安装完整。
        pause
        exit /b 1
    )
    echo       完成！
    echo.
)

call venv\Scripts\activate.bat

:: ---- 安装依赖 ----
echo [2/3] 正在安装所需组件...
echo.
:: 【如果依赖较大，取消下面注释并修改提示】
:: echo ================================================
:: echo   首次安装需要下载较多依赖文件
:: echo   可能需要 5-10 分钟，请耐心等待
:: echo   请不要关闭此窗口！
:: echo ================================================
:: echo.
pip install -r requirements.txt -q
pip install gradio -q

:: ---- 启动 ----
echo [3/3] 正在启动，请稍候...
echo.
echo 启动成功后，浏览器会自动打开。如果没有自动打开，
echo 请手动在浏览器地址栏输入：http://localhost:7860
echo.
echo 关闭此黑色窗口即可停止程序。
echo.
python webui.py

pause
```

### `install_and_run.bat` 模板（自带 WebUI 的项目，不需要包装）

适用于 open-webui 等本身就是 Web 应用的项目：

```bat
@echo off
title 项目名称

echo ============================================
echo   项目名称 一键整合包
echo   简短描述
echo ============================================
echo.

:: ---- Python 版本检测 ----
set "PYTHON_CMD="
set "PY_VER=3.11"

py -%PY_VER% --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=py -%PY_VER%"
    goto :python_ok
)

for /f "tokens=2 delims= " %%v in ('python --version 2^>nul') do (
    echo %%v | findstr /b "%PY_VER%" >nul
    if not errorlevel 1 (
        set "PYTHON_CMD=python"
        goto :python_ok
    )
)

echo [提示] 未检测到 Python %PY_VER%，正在为您自动安装...
echo        这需要大约 1-2 分钟，请耐心等待。
echo.
winget install -e --id Python.Python.%PY_VER% --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
    echo.
    echo [错误] 自动安装 Python %PY_VER% 失败。
    echo 请手动安装后重新双击本程序。
    pause
    exit /b 1
)
echo.
echo [完成] Python %PY_VER% 安装成功！请关闭此窗口，然后重新双击本程序。
pause
exit /b 0

:python_ok
echo [√] 已检测到 Python %PY_VER%
echo.

:: ---- 虚拟环境 ----
if not exist "venv" (
    echo [1/3] 正在创建专属运行环境...
    %PYTHON_CMD% -m venv venv
    if errorlevel 1 (
        echo [错误] 创建虚拟环境失败。
        pause
        exit /b 1
    )
    echo       完成！
    echo.
)

call venv\Scripts\activate.bat

:: ---- 安装项目 ----
echo [2/3] 正在安装...
echo.
echo ================================================
echo   首次安装需要下载较多依赖文件
echo   可能需要 5-10 分钟，请耐心等待
echo   请不要关闭此窗口！
echo ================================================
echo.

pip install 项目包名
if errorlevel 1 (
    echo.
    echo [错误] 安装失败。请检查网络连接后重新双击本程序。
    pause
    exit /b 1
)

echo.
echo [√] 安装完成！
echo.

:: ---- 启动前引导（根据项目情况填写）----
echo [3/3] 正在启动...
echo.
echo ================================================
echo   【在这里写项目特有的配置引导信息】
echo   例如：浏览器打开后需要填入 API Key，
echo   或者需要先安装某个本地服务等等。
echo ================================================
echo.
echo   正在打开浏览器... 如果没有自动打开，
echo   请手动访问：http://localhost:端口号
echo.
echo   关闭此黑色窗口即可停止程序。
echo.

start "" http://localhost:端口号
项目启动命令

pause
```

**关键区别**：自带 WebUI 的项目不需要 `webui.py`，不需要安装 Gradio/Streamlit，直接用项目自己的启动命令。

**根据上面的判断规则选择框架后**，生成对应的 `webui.py`：

**Gradio 版模板**（AI/图像/文本类项目）：

```python
import gradio as gr

# 根据项目实际情况导入对应模块
# from <项目模块> import <核心函数>

def process(输入):
    """调用项目核心功能，返回结果"""
    # 实际调用代码写在这里
    return "结果"

with gr.Blocks(title="项目名称") as demo:
    gr.Markdown("# 项目名称\n简短描述这个工具是干什么的")

    with gr.Row():
        with gr.Column():
            # 根据输入类型选择：文字→Textbox，图片→Image，文件→File
            inp = gr.Textbox(label="输入", placeholder="在这里输入内容...")
            btn = gr.Button("运行", variant="primary")
        with gr.Column():
            out = gr.Textbox(label="输出结果")

    btn.click(fn=process, inputs=inp, outputs=out)

if __name__ == "__main__":
    demo.launch(inbrowser=True)
```

**Streamlit 版模板**（数据/多页/通用工具类项目）：

```python
import streamlit as st

# 根据项目实际情况导入对应模块

st.title("项目名称")
st.caption("简短描述这个工具是干什么的")

# 根据输入类型选择：文字→st.text_input，文件→st.file_uploader
user_input = st.text_input("输入内容")

if st.button("运行"):
    with st.spinner("处理中..."):
        # 实际调用代码写在这里
        result = "结果"
    st.success("完成！")
    st.write(result)
```

---

## 第四步：输出给用户

生成文件后，告诉用户：

1. **你做了什么**：用一句话描述项目功能
2. **怎么用**：
   - 把文件放到一个文件夹里（如果只有 bat 就说"把这个文件放到一个空文件夹里"）
   - 双击 `install_and_run.bat`
   - 等它自动安装（第一次比较慢，之后就快了）
   - 浏览器会自动打开，就可以用了
3. **注意事项**：
   - 如果有 Python 版本要求，明确告知（如"需要 Python 3.11"）
   - 如果安装包很大，提醒用户首次安装要等待
   - 如果启动后需要配置（API Key 等），简单说明步骤

---

## 重要原则

- **用大白话**：和用户说话时不要用技术术语，说"双击打开"而不是"执行脚本"
- **宁可啰嗦也要清楚**：bat 文件里的提示信息要写清楚，让用户知道程序在干什么
- **遇到不确定的情况要说出来**：如果项目结构复杂，你不确定 WebUI 怎么包，先告诉用户，给出你最好的尝试，并说明可能需要微调
- **错误信息要友好**：bat 里的报错信息用中文写，并告诉用户下一步该怎么做

---

## 踩坑经验（血泪教训，务必遵守）

### 1. bat 文件编码必须是 GBK

- **绝对不能用 UTF-8 保存 bat 文件**，否则中文全部乱码
- **不要加 `chcp 65001`**，这救不了 UTF-8 编码的 bat 文件
- 生成 bat 后必须执行：`iconv -f UTF-8 -t GBK xxx.bat > xxx_gbk.bat && mv xxx_gbk.bat xxx.bat`
- 验证方法：`iconv -f GBK -t UTF-8 xxx.bat` 能正确显示中文就对了

### 2. Python 版本必须锁定，不能装"最新版"

- `winget install Python.Python.3` 会装最新版（可能是 3.13），很多项目会不兼容
- 必须指定到小版本：`winget install Python.Python.3.11`
- 用户电脑上可能已经装了其他版本的 Python，所以要用 `py -3.11` 而不是 `python`
- 在 bat 里用变量 `set "PY_VER=3.11"` 方便统一管理

### 3. 项目自带 WebUI 就别再包一层

- 如果项目本身就是 Web 应用（open-webui、Lobe Chat 等），直接启动就行
- **千万不要再套一个 Gradio/Streamlit 界面**，这是多此一举
- 判断标准：项目 README 提到 `visit http://localhost:xxxx` 或者有 `serve`/`start` 命令
- 这类项目只需要一个 bat 文件，不需要生成 `webui.py`

### 4. 大依赖包要提前告知等待时间

- 很多项目 `pip install` 要下载几百 MB 甚至几 GB 的依赖（PyTorch、transformers 等）
- 用户看到命令行一直滚动会以为卡死了，**必须提前打印等待提示**
- 不要加 `-q`（quiet）参数，让用户能看到下载进度
- 示例提示：`首次安装需要下载约 500MB 的依赖文件，可能需要 5-10 分钟，请不要关闭此窗口`

### 5. 启动后的配置引导不能少

- 很多项目装完打开是空的，需要用户自己配置（API Key、模型来源等）
- 如果不告诉用户，他们打开一脸懵，以为安装出了问题
- **在启动命令之前**打印配置引导，告诉用户：
  - 浏览器打开后该干什么
  - 去哪里填配置信息
  - 有哪几种配置方式
