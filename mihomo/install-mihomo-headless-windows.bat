@echo off
REM 启动器:以绕过执行策略的方式调用 PowerShell 安装脚本
REM 用法: install-mihomo-headless-windows.bat [-SubUrl <订阅URL>] [-AsService] [-SetProxy] [-EnableTun]
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-mihomo-headless-windows.ps1" %*
pause
