@echo off
setlocal
rem RKDevTool resolves config.cfg from the current working directory,
rem so the launcher must run inside the tool folder.
cd /d "%~dp0rktools\RKDevTool"
if not exist "RKDevTool.exe" (
    echo RKDevTool.exe not found in:
    echo   %CD%
    pause
    exit /b 1
)
start "" "RKDevTool.exe"
endlocal
