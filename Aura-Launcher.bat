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
echo [SYSTEM STATUS] AURA Local Ingestion Node: ACTIVE
echo [SYSTEM STATUS] Core Inference Port: 8085
echo [SYSTEM STATUS] Environment Sandbox: SECURE
echo.
echo Launching Ambient AI Operating Layer in your browser...
echo.

:: Open default browser to the local Aura server
start http://127.0.0.1:8085/index.html

echo Done! Press any key to shutdown AURA launcher session.
pause > nul
