"""MetaGPT WebUI - 可视化控制面板"""
import gradio as gr
import subprocess
import os
import sys

# Detect Gradio major version for API compatibility
_GRADIO_MAJOR = int(gr.__version__.split(".")[0]) if hasattr(gr, "__version__") else 4

try:
    import yaml
except ImportError:
    yaml = None

# ============================================
#  全局状态
# ============================================
PROCESS = None
LOG_TEXT = ""
CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".metagpt")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config2.yaml")
WORKSPACE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "workspace")

# ============================================
#  配置管理
# ============================================
LLM_PROVIDERS = {
    "OpenAI": {"api_type": "openai", "base_url": "https://api.openai.com/v1", "models": ["gpt-4o", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"]},
    "Anthropic Claude": {"api_type": "anthropic", "base_url": "https://api.anthropic.com", "models": ["claude-sonnet-4-5-20250929", "claude-opus-4-20250514", "claude-haiku-4-5-20251001"]},
    "DeepSeek": {"api_type": "openai", "base_url": "https://api.deepseek.com/v1", "models": ["deepseek-chat", "deepseek-coder"]},
    "Ollama (本地)": {"api_type": "ollama", "base_url": "http://localhost:11434/api", "models": ["llama3", "qwen2", "codellama", "mistral"]},
    "自定义 (兼容 OpenAI)": {"api_type": "openai", "base_url": "", "models": []},
}


def load_config():
    """加载现有配置"""
    if not os.path.exists(CONFIG_FILE):
        return {}
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            text = f.read()
        if yaml:
            return yaml.safe_load(text) or {}
        # Fallback: minimal parser for simple key: value YAML
        return _parse_simple_yaml(text)
    except Exception:
        return {}


def _parse_simple_yaml(text):
    """Minimal YAML parser - handles only the simple config2.yaml format"""
    result = {}
    current_section = None
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if ":" not in stripped:
            continue
        key, _, value = stripped.partition(":")
        key = key.strip()
        value = value.strip()
        if not value:
            # Section header like "llm:"
            result[key] = {}
            current_section = key
        elif current_section and line.startswith((" ", "\t")):
            result[current_section][key] = value
        else:
            result[key] = value
    return result


def save_config(provider, api_key, model, base_url):
    """保存配置到 config2.yaml"""
    os.makedirs(CONFIG_DIR, exist_ok=True)

    provider_info = LLM_PROVIDERS.get(provider, {})
    api_type = provider_info.get("api_type", "openai")
    if not base_url:
        base_url = provider_info.get("base_url", "")

    config = {
        "llm": {
            "api_type": api_type,
            "model": model,
            "base_url": base_url,
            "api_key": api_key,
        }
    }

    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        if yaml:
            yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
        else:
            # Fallback: write simple YAML manually
            llm = config.get("llm", {})
            f.write("llm:\n")
            for k, v in llm.items():
                f.write(f"  {k}: {v}\n")

    return f"配置已保存到 {CONFIG_FILE}"


def get_current_config():
    """获取当前配置的显示信息"""
    config = load_config()
    if not config or "llm" not in config:
        return "尚未配置，请在下方设置 API Key"
    llm = config["llm"]
    api_key = llm.get("api_key", "")
    masked_key = api_key[:8] + "****" + api_key[-4:] if len(api_key) > 12 else "****"
    return f"模型: {llm.get('model', '未设置')} | API类型: {llm.get('api_type', '未设置')} | Key: {masked_key}"


def on_provider_change(provider):
    """当提供商变化时更新模型列表和 base_url"""
    info = LLM_PROVIDERS.get(provider, {})
    models = info.get("models", [])
    base_url = info.get("base_url", "")
    model_default = models[0] if models else ""
    is_custom = provider == "自定义 (兼容 OpenAI)"
    return (
        gr.update(choices=models, value=model_default, allow_custom_value=True),
        gr.update(value=base_url, interactive=is_custom),
    )


# ============================================
#  MetaGPT 运行
# ============================================
def run_metagpt(idea, enable_code_review):
    """运行 MetaGPT 生成项目"""
    global PROCESS, LOG_TEXT

    if not idea.strip():
        yield "请输入你的项目想法！", ""
        return

    config = load_config()
    if not config or "llm" not in config:
        yield "请先在「设置」页面配置 API Key！", ""
        return

    if PROCESS and PROCESS.poll() is None:
        yield "已有任务在运行中，请等待完成或停止当前任务。", LOG_TEXT
        return

    LOG_TEXT = ""
    os.makedirs(WORKSPACE_DIR, exist_ok=True)

    python_exe = os.path.join(os.path.dirname(os.path.abspath(__file__)), "runtime", "python", "python.exe")
    if not os.path.exists(python_exe):
        python_exe = sys.executable

    cmd = [python_exe, "-m", "metagpt.software_company"]
    cmd.append(idea)
    if not enable_code_review:
        cmd.extend(["--no-code-review"])
    cmd.extend(["--project-path", WORKSPACE_DIR])

    yield "正在启动 MetaGPT...", ""

    try:
        PROCESS = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            cwd=os.path.dirname(os.path.abspath(__file__)),
            env={**os.environ, "PYTHONIOENCODING": "utf-8"},
        )

        for line in PROCESS.stdout:
            LOG_TEXT += line
            # 每收到新输出就更新界面
            status = "正在运行..." if PROCESS.poll() is None else "已完成"
            yield status, LOG_TEXT

        PROCESS.wait()

        if PROCESS.returncode == 0:
            yield "项目生成完成！请到「查看项目」页面查看结果。", LOG_TEXT
        else:
            yield f"运行结束（退出码: {PROCESS.returncode}），请查看日志。", LOG_TEXT

    except FileNotFoundError:
        LOG_TEXT += "\n[错误] 找不到 Python 或 MetaGPT，请确认已正确安装。\n"
        yield "运行失败", LOG_TEXT
    except Exception as e:
        LOG_TEXT += f"\n[错误] {e}\n"
        yield "运行失败", LOG_TEXT


def stop_metagpt():
    """停止正在运行的 MetaGPT"""
    global PROCESS
    if PROCESS and PROCESS.poll() is None:
        PROCESS.terminate()
        try:
            PROCESS.wait(timeout=5)
        except subprocess.TimeoutExpired:
            PROCESS.kill()
        return "已停止"
    return "没有正在运行的任务"


# ============================================
#  项目文件浏览
# ============================================
def list_projects():
    """列出生成的项目"""
    if not os.path.exists(WORKSPACE_DIR):
        return "还没有生成过项目。去「生成项目」页面试试吧！"

    projects = []
    for item in sorted(os.listdir(WORKSPACE_DIR)):
        item_path = os.path.join(WORKSPACE_DIR, item)
        if os.path.isdir(item_path):
            file_count = sum(len(files) for _, _, files in os.walk(item_path))
            projects.append(f"📁 {item}  ({file_count} 个文件)")

    if not projects:
        return "还没有生成过项目。去「生成项目」页面试试吧！"

    return "\n".join(projects)


def browse_project(project_name):
    """浏览项目文件树"""
    if not project_name:
        return "请选择一个项目", ""

    # 清理项目名（去掉图标和文件数信息）
    clean_name = project_name.replace("📁 ", "").split("  (")[0].strip()
    project_path = os.path.join(WORKSPACE_DIR, clean_name)

    if not os.path.exists(project_path):
        return f"项目不存在: {clean_name}", ""

    tree_lines = []
    for root, dirs, files in os.walk(project_path):
        level = root.replace(project_path, "").count(os.sep)
        indent = "  " * level
        tree_lines.append(f"{indent}📁 {os.path.basename(root)}/")
        sub_indent = "  " * (level + 1)
        for file in sorted(files):
            tree_lines.append(f"{sub_indent}📄 {file}")

    return "\n".join(tree_lines), ""


def read_project_file(project_name, file_path):
    """读取项目中的某个文件"""
    if not project_name or not file_path:
        return "请选择项目和文件路径"

    clean_name = project_name.replace("📁 ", "").split("  (")[0].strip()
    full_path = os.path.normpath(os.path.join(WORKSPACE_DIR, clean_name, file_path.strip()))

    # Prevent path traversal (e.g. ../../etc/passwd)
    if not full_path.startswith(os.path.normpath(WORKSPACE_DIR)):
        return "非法路径"

    if not os.path.exists(full_path):
        return f"文件不存在: {file_path}"
    if os.path.isdir(full_path):
        return "这是一个文件夹，请输入文件路径"

    try:
        with open(full_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        return content[:50000]  # 限制大小
    except Exception as e:
        return f"读取失败: {e}"


# ============================================
#  Gradio UI
# ============================================
CUSTOM_CSS = """
.main-title { text-align: center; margin-bottom: 0; }
.sub-title { text-align: center; color: #666; margin-top: 0; }
"""


def create_ui():
    # Gradio 6.0 deprecated theme/css in Blocks constructor
    if _GRADIO_MAJOR >= 6:
        block_kwargs = {"title": "MetaGPT 控制面板"}
    else:
        block_kwargs = {
            "title": "MetaGPT 控制面板",
            "theme": gr.themes.Soft(),
            "css": CUSTOM_CSS,
        }

    with gr.Blocks(**block_kwargs) as app:

        # Inject CSS via HTML for Gradio 6.x
        if _GRADIO_MAJOR >= 6:
            gr.HTML(f"<style>{CUSTOM_CSS}</style>")

        gr.Markdown("# 🤖 MetaGPT 控制面板", elem_classes="main-title")
        gr.Markdown("多智能体协作框架 — 输入你的想法，AI 团队帮你写代码", elem_classes="sub-title")

        # ============ Tab 1: 生成项目 ============
        with gr.Tab("🚀 生成项目"):
            config_status = gr.Textbox(
                label="当前配置",
                value=get_current_config(),
                interactive=False,
            )

            idea_input = gr.Textbox(
                label="你的项目想法",
                placeholder="例如：帮我做一个贪吃蛇游戏\n例如：创建一个待办事项管理 Web 应用\n例如：写一个能自动整理文件的 Python 脚本",
                lines=3,
            )

            with gr.Row():
                code_review = gr.Checkbox(label="启用代码审查（更严谨但更慢）", value=True)

            with gr.Row():
                run_btn = gr.Button("🚀 开始生成", variant="primary", scale=3)
                stop_btn = gr.Button("⏹ 停止", variant="stop", scale=1)

            status_output = gr.Textbox(label="状态", interactive=False)
            try:
                log_output = gr.Textbox(label="运行日志", lines=20, interactive=False, autoscroll=True)
            except TypeError:
                log_output = gr.Textbox(label="运行日志", lines=20, interactive=False)

            run_btn.click(
                run_metagpt,
                inputs=[idea_input, code_review],
                outputs=[status_output, log_output],
            )
            stop_btn.click(stop_metagpt, outputs=status_output)

        # ============ Tab 2: 查看项目 ============
        with gr.Tab("📁 查看项目"):
            refresh_btn = gr.Button("🔄 刷新项目列表")
            project_list = gr.Textbox(
                label="已生成的项目",
                value=list_projects(),
                lines=8,
                interactive=False,
            )

            with gr.Row():
                project_select = gr.Textbox(
                    label="输入项目名称（上面列表中的名称）",
                    placeholder="例如：snake_game",
                )
                browse_btn = gr.Button("📂 浏览文件树")

            file_tree = gr.Textbox(label="文件树", lines=15, interactive=False)

            with gr.Row():
                file_path_input = gr.Textbox(
                    label="输入文件路径查看内容",
                    placeholder="例如：main.py 或 src/app.py",
                )
                read_btn = gr.Button("📄 查看文件")

            file_content = gr.Code(label="文件内容", language="python", lines=20)

            refresh_btn.click(list_projects, outputs=project_list)
            browse_btn.click(browse_project, inputs=project_select, outputs=[file_tree, file_content])
            read_btn.click(read_project_file, inputs=[project_select, file_path_input], outputs=file_content)

        # ============ Tab 3: 设置 ============
        with gr.Tab("⚙️ 设置"):
            gr.Markdown("### LLM 大模型配置")
            gr.Markdown("MetaGPT 需要一个大模型 API 来工作。选择你的提供商并填入 API Key。")

            provider_dropdown = gr.Dropdown(
                label="选择提供商",
                choices=list(LLM_PROVIDERS.keys()),
                value="OpenAI",
            )

            api_key_input = gr.Textbox(
                label="API Key",
                placeholder="sk-xxxxxxxxxxxxxxxx",
                type="password",
            )

            model_dropdown = gr.Dropdown(
                label="模型",
                choices=LLM_PROVIDERS["OpenAI"]["models"],
                value="gpt-4o",
                allow_custom_value=True,
            )

            base_url_input = gr.Textbox(
                label="Base URL（一般不需要改）",
                value="https://api.openai.com/v1",
                interactive=False,
            )

            save_btn = gr.Button("💾 保存配置", variant="primary")
            save_status = gr.Textbox(label="保存结果", interactive=False)

            provider_dropdown.change(
                on_provider_change,
                inputs=provider_dropdown,
                outputs=[model_dropdown, base_url_input],
            )

            save_btn.click(
                save_config,
                inputs=[provider_dropdown, api_key_input, model_dropdown, base_url_input],
                outputs=save_status,
            )

            gr.Markdown("---")
            gr.Markdown("### 使用说明")
            gr.Markdown("""
- **OpenAI**: 需要 OpenAI API Key，在 [platform.openai.com](https://platform.openai.com/api-keys) 获取
- **Anthropic Claude**: 需要 Anthropic API Key，在 [console.anthropic.com](https://console.anthropic.com/) 获取
- **DeepSeek**: 需要 DeepSeek API Key，在 [platform.deepseek.com](https://platform.deepseek.com/) 获取
- **Ollama (本地)**: 需要先安装 [Ollama](https://ollama.ai/) 并下载模型，无需 API Key
- **自定义**: 任何兼容 OpenAI API 的服务均可使用
            """)

    return app


if __name__ == "__main__":
    app = create_ui()
    app.launch(
        server_name="127.0.0.1",
        server_port=7860,
        inbrowser=True,
        share=False,
    )
