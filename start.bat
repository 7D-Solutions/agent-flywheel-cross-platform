@echo off
REM Windows launcher for Agent Flywheel
REM Automatically detects and sets up WSL if needed

setlocal enabledelayedexpansion

echo ========================================
echo   Agent Flywheel - Windows Launcher
echo ========================================
echo.

REM Check if WSL is installed
wsl --list >nul 2>&1
if errorlevel 1 (
    echo WSL is not installed on this system.
    echo.
    echo Agent Flywheel requires WSL ^(Windows Subsystem for Linux^) to run.
    echo WSL is free and built into Windows 10/11.
    echo.
    echo Would you like to install WSL now? ^(Requires admin privileges^)
    echo.
    echo   [Y] Yes, install WSL ^(recommended^)
    echo   [N] No, show me manual instructions
    echo.
    choice /C YN /N /M "Your choice: "

    if errorlevel 2 (
        echo.
        echo Manual Installation Instructions:
        echo.
        echo 1. Open PowerShell as Administrator
        echo 2. Run: wsl --install
        echo 3. Restart your computer
        echo 4. Run this script again
        echo.
        echo For more info: https://aka.ms/wsl
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Installing WSL... This will take a few minutes.
    echo You may be prompted for administrator permission.
    echo.

    REM Try to install WSL
    powershell -Command "Start-Process wsl -ArgumentList '--install' -Verb RunAs -Wait"

    if errorlevel 1 (
        echo.
        echo Installation failed or was cancelled.
        echo.
        echo Please install WSL manually:
        echo 1. Open PowerShell as Administrator
        echo 2. Run: wsl --install
        echo 3. Restart your computer
        echo.
        pause
        exit /b 1
    )

    echo.
    echo ========================================
    echo   WSL Installation Complete!
    echo ========================================
    echo.
    echo IMPORTANT: You must RESTART YOUR COMPUTER now.
    echo.
    echo After restarting:
    echo 1. Open Command Prompt or PowerShell
    echo 2. Run: start.bat
    echo.
    pause
    exit /b 0
)

REM WSL is installed, check if we have a distribution
wsl --list --quiet | findstr /R "." >nul 2>&1
if errorlevel 1 (
    echo WSL is installed but no Linux distribution found.
    echo.
    echo Installing Ubuntu ^(this is quick^)...
    echo.
    wsl --install -d Ubuntu

    echo.
    echo Ubuntu installed! Setting up Agent Flywheel...
    echo.
)

REM Get the current Windows directory
set "WIN_DIR=%CD%"

REM Convert Windows path to WSL path
for /f "usebackq tokens=*" %%i in (`wsl wslpath -a "%WIN_DIR%"`) do set "WSL_DIR=%%i"

echo Starting Agent Flywheel in WSL...
echo.

REM Check if the project exists in WSL
wsl test -d "%WSL_DIR%" 2>nul
if errorlevel 1 (
    echo Error: Project directory not accessible from WSL
    echo.
    echo Please run this script from the agent-flywheel directory:
    echo   cd path\to\agent-flywheel-cross-platform
    echo   start.bat
    echo.
    pause
    exit /b 1
)

REM First time setup check
wsl test -f "%WSL_DIR%/install.sh" 2>nul
if not errorlevel 1 (
    wsl test -f "%WSL_DIR%/.install-complete" 2>nul
    if errorlevel 1 (
        echo First time setup detected.
        echo Running installer...
        echo.
        wsl bash -c "cd '%WSL_DIR%' && chmod +x install.sh && ./install.sh"

        if not errorlevel 1 (
            wsl touch "%WSL_DIR%/.install-complete"
        )
        echo.
    )
)

REM Make scripts executable
wsl bash -c "cd '%WSL_DIR%' && chmod +x start setup-fzf.sh scripts/*.sh" 2>nul

REM Launch the visual interface
wsl bash -c "cd '%WSL_DIR%' && ./start"

echo.
echo Agent Flywheel session ended.
echo.
pause
