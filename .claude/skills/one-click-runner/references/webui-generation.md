# WebUI Generation Guide

When a project has no built-in WebUI, generate a simple control panel. Choose the approach based on what's already available in the project.

## Approach Selection

1. **Project already has Python** → Use Gradio (simplest, fewest dependencies)
2. **Project already has Node.js** → Use a simple Express + HTML page
3. **Project is a CLI binary** → Use Python + Gradio (add embedded Python to the package)

## Gradio Control Panel (Recommended)

Gradio is the simplest way to wrap any CLI tool with a WebUI. One Python file, one dependency.

### Template: `webui.py`

```python
"""Auto-generated WebUI control panel"""
import gradio as gr
import subprocess
import threading
import os
import signal

PROCESS = None
LOG_TEXT = ""

def run_command(cmd, cwd=None):
    """Run a command and capture output in real-time."""
    global PROCESS, LOG_TEXT
    LOG_TEXT = ""
    try:
        PROCESS = subprocess.Popen(
            cmd, shell=True, cwd=cwd,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, bufsize=1
        )
        for line in PROCESS.stdout:
            LOG_TEXT += line
        PROCESS.wait()
    except Exception as e:
        LOG_TEXT += f"\nError: {e}"
    return LOG_TEXT

def start_project():
    global PROCESS
    if PROCESS and PROCESS.poll() is None:
        return "Project is already running!"
    # TODO: Replace with actual start command
    thread = threading.Thread(target=run_command, args=("COMMAND_HERE",))
    thread.daemon = True
    thread.start()
    return "Starting..."

def stop_project():
    global PROCESS
    if PROCESS and PROCESS.poll() is None:
        PROCESS.terminate()
        return "Stopped."
    return "Not running."

def get_logs():
    return LOG_TEXT or "No logs yet."

with gr.Blocks(title="Project Control Panel") as app:
    gr.Markdown("# Project Control Panel")
    with gr.Row():
        start_btn = gr.Button("Start", variant="primary")
        stop_btn = gr.Button("Stop", variant="stop")
    status = gr.Textbox(label="Status", interactive=False)
    logs = gr.Textbox(label="Logs", lines=20, interactive=False)
    refresh_btn = gr.Button("Refresh Logs")

    start_btn.click(start_project, outputs=status)
    stop_btn.click(stop_project, outputs=status)
    refresh_btn.click(get_logs, outputs=logs)

if __name__ == "__main__":
    app.launch(inbrowser=True)
```

### Customization points:
- Replace `COMMAND_HERE` with the actual project start command
- Add `gr.Textbox` / `gr.Slider` / `gr.Dropdown` for project configuration options
- Add `gr.File` for file upload if the project processes files
- Add `gr.Image` for image display if relevant

### Dependencies:
```
gradio>=4.0
```

## Express Control Panel (for Node.js projects)

### Template: `control-panel.js`

```javascript
const express = require('express');
const { spawn } = require('child_process');
const app = express();
let proc = null;
let logs = '';

app.use(express.static('public'));
app.use(express.json());

app.post('/start', (req, res) => {
    if (proc) return res.json({ status: 'Already running' });
    // TODO: Replace with actual command
    proc = spawn('node', ['index.js'], { shell: true });
    proc.stdout.on('data', d => logs += d);
    proc.stderr.on('data', d => logs += d);
    proc.on('close', () => { proc = null; });
    res.json({ status: 'Started' });
});

app.post('/stop', (req, res) => {
    if (proc) { proc.kill(); proc = null; logs += '\nStopped.\n'; }
    res.json({ status: 'Stopped' });
});

app.get('/logs', (req, res) => res.json({ logs }));

app.listen(7860, () => {
    console.log('Control panel: http://localhost:7860');
    require('child_process').exec('start http://localhost:7860');
});
```

Pair with a simple `public/index.html` containing start/stop buttons and a log viewer.
