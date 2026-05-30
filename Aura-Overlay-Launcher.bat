@echo off
title AURA Universal Overlay Launcher
color 0b

echo Starting AURA Backend with Hermes Agent Bridge (port 7860)...
start "AURA Backend" /min py "%~dp0python_backend\main.py"

echo Waiting for backend...
timeout /t 4 /nobreak > nul

echo Starting Windows Overlay (Electron)...
cd /d "%~dp0desktop_overlay"
start "AURA Overlay" npm start

echo.
echo AURA Overlay is launching.
echo Ensure GROQ_API_KEY is set in python_backend\.env
pause
