@echo off
setlocal
rem Usage: flash-rk3588.bat [RKDevTool-directory]
set "toolDir=%~1"
if not defined toolDir set "toolDir=%RKDEVTOOL_DIR%"
if not defined toolDir set "toolDir=%~dp0..\..\rktools\RKDevTool"
if not exist "%toolDir%\RKDevTool.exe" (
    echo RKDevTool.exe not found. Pass its directory as the first argument,
    echo or set RKDEVTOOL_DIR. See docs\05-flashing.md.
    exit /b 1
)
if not exist "%toolDir%\config.cfg" (
    powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0Prepare-FlashConfig.ps1" -ToolDirectory "%toolDir%"
    if errorlevel 1 exit /b 1
)
rem RKDevTool reads config.cfg from its working directory.
pushd "%toolDir%" || exit /b 1
start "" "RKDevTool.exe"
popd
endlocal
