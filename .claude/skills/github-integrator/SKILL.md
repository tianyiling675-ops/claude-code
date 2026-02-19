---
name: github-integrator
description: 为 GitHub 开源项目生成 Windows 一键整合包，包含自动安装脚本和 WebUI 前端。当用户发来 GitHub 链接并说"帮我做个整合包"时触发此 Skill。
---

# GitHub 项目整合包生成器

## 你的任务

用户是编程小白，他们喜欢体验开源项目，但搞不定各种环境和命令。你的任务是：

1. 读取用户发来的 GitHub 项目
2. 理解这个项目是干什么的、怎么运行的
3. 生成一个 **Windows 一键整合包**，包含：
   - `install_and_run.bat`：双击即可自动安装依赖并启动项目
   - `webui.py`（或类似文件）：用 Gradio 或 Streamlit 包装的网页界面，在浏览器里打开即可使用

交付给用户的东西要让他们**不需要懂任何命令行**，下载下来双击就能跑。

---

## 第一步：分析项目

用户发来 GitHub 链接后，你需要先搞清楚这个项目的基本情况：

**必须确认的信息：**

- 项目用什么语言写的？（Python / Node.js / 其他）
- 依赖怎么管理的？（pip + requirements.txt / conda / npm / 其他）
- 项目的入口是什么？（哪个文件、哪个命令可以启动它）
- 项目本身有没有提供任何 API 或者函数接口？（决定 WebUI 怎么包装）

**分析方法：**

- 优先读 README.md，找"Installation"和"Usage"部分
- 查看根目录是否有 `requirements.txt`、`setup.py`、`pyproject.toml`、`package.json` 等文件
- 找主入口文件（通常是 `main.py`、`app.py`、`cli.py` 等）

如果用户只发了链接，你需要通过 fetch 工具去读取 GitHub 页面或原始文件内容。

---

## 第二步：判断项目类型，选择打包方案

### 类型 A：Python 项目（最常见，优先支持）

**条件**：有 `requirements.txt` 或 `setup.py`，主文件是 `.py`

**打包方案**：

`install_and_run.bat` 做以下事情：

1. 检查 Python 是否已安装；**没有则用 `winget install Python.Python.3` 自动安装**，安装完后提示用户重新双击运行
2. 创建虚拟环境（`python -m venv venv`）
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

### `install_and_run.bat` 模板（Python 项目）

```bat
@echo off
chcp 65001 >nul
title 项目启动器

echo ========================================
echo  欢迎使用！正在为您自动安装和启动...
echo ========================================
echo.

:: 检查 Python 是否已安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [提示] 您的电脑上还没有安装 Python，正在自动为您安装...
    echo 这需要大约 1-2 分钟，请耐心等待。
    echo.
    winget install -e --id Python.Python.3 --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo [错误] 自动安装 Python 失败。
        echo 请手动去这里下载安装：https://www.python.org/downloads/
        echo 安装时记得勾选最下面那个 "Add Python to PATH" 选项！
        echo 安装完成后，重新双击本程序即可。
        pause
        exit /b 1
    )
    echo.
    echo [完成] Python 安装成功！
    echo 请关闭此窗口，然后重新双击启动程序。
    pause
    exit /b 0
)

:: 创建虚拟环境（如果还没有）
if not exist "venv" (
    echo [1/3] 正在创建专属运行环境...
    python -m venv venv
)

:: 激活虚拟环境
call venv\Scripts\activate.bat

:: 安装依赖
echo [2/3] 正在安装所需组件（首次运行可能需要几分钟）...
pip install -r requirements.txt -q
pip install gradio streamlit -q

:: 启动
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
   - 把这两个文件放到项目文件夹里
   - 双击 `install_and_run.bat`
   - 等它自动安装（第一次比较慢，之后就快了）
   - 浏览器会自动打开，就可以用了
3. **注意事项**：如果有什么需要用户提前准备的（比如需要先安装 Python），在这里说清楚

---

## 重要原则

- **用大白话**：和用户说话时不要用技术术语，说"双击打开"而不是"执行脚本"
- **宁可啰嗦也要清楚**：bat 文件里的提示信息要写清楚，让用户知道程序在干什么
- **遇到不确定的情况要说出来**：如果项目结构复杂，你不确定 WebUI 怎么包，先告诉用户，给出你最好的尝试，并说明可能需要微调
- **错误信息要友好**：bat 里的报错信息用中文写，并告诉用户下一步该怎么做
