@echo off
title AURA Neural Operating Layer Launcher
color 0b
cls

echo ====================================================================
echo.
echo    AAAA    UU   UU  RRRRRR    AAAA       OOOOO    SSSSS   
echo   AA  AA   UU   UU  RR   RR  AA  AA     OO   OO  SS       
echo   AAAAAA   UU   UU  RRRRRR   AAAAAA     OO   OO   SSSSS   
echo   AA  AA   UU   UU  RR  RR   AA  AA     OO   OO       SS  
echo   AA  AA    UUUUU   RR   RR  AA  AA      OOOO0    SSSSS   
echo.
echo ====================================================================
echo             AURA NEURAL OS LAYER - WINDOWS DESKTOP LAUNCHER
echo ====================================================================
echo.
echo [SYSTEM] Starting Core LRM FastAPI Backend on port 7860...
start "AURA Backend" /min py python_backend/main.py

echo [SYSTEM] Starting Ambient Web Server on port 8085...
start "AURA Web Server" /min py -m http.server 8085 --directory aura_web_portal

echo [SYSTEM] Waiting for cognitive cores to initialize...
timeout /t 3 /nobreak > nul

echo [SYSTEM STATUS] AURA Local Ingestion Node: ACTIVE
echo [SYSTEM STATUS] Core Inference Port: 8085
echo [SYSTEM STATUS] Environment Sandbox: SECURE
echo.
echo Launching Ambient AI Operating Layer in your browser...
echo.

:: Open default browser to the local Aura server
start http://127.0.0.1:8085/index.html

echo.
echo ====================================================================
echo AURA is running. Press any key in this window to shutdown AURA services.
echo ====================================================================
echo.
pause > nul

echo [SYSTEM] Stopping AURA background tasks...
taskkill /fi "windowtitle eq AURA Backend*" /f > nul 2>&1
taskkill /fi "windowtitle eq AURA Web Server*" /f > nul 2>&1
echo Done!
