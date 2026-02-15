@echo off
chcp 65001 >nul 2>&1
title 停止 MetaGPT
echo 正在停止 MetaGPT...

taskkill /f /im python.exe /fi "WINDOWTITLE eq MetaGPT*" >nul 2>&1
taskkill /f /im node.exe >nul 2>&1

REM 通过端口关闭（Gradio 默认端口 7860）
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :7860 ^| findstr LISTENING') do (
    taskkill /f /pid %%a >nul 2>&1
)

echo MetaGPT 已停止。
timeout /t 2 >nul
