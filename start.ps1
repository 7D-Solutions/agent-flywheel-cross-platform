# PowerShell launcher for Agent Flywheel
# Automatically detects and sets up WSL if needed

Write-Host "========================================" -ForegroundColor Blue
Write-Host "  Agent Flywheel - Windows Launcher" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

# Check if WSL is installed
try {
    $wslCheck = wsl --list 2>&1
    $wslInstalled = $LASTEXITCODE -eq 0
} catch {
    $wslInstalled = $false
}

if (-not $wslInstalled) {
    Write-Host "WSL is not installed on this system." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Agent Flywheel requires WSL (Windows Subsystem for Linux) to run."
    Write-Host "WSL is free and built into Windows 10/11."
    Write-Host ""

    $install = Read-Host "Would you like to install WSL now? (requires admin) [Y/n]"

    if ($install -eq "" -or $install -eq "Y" -or $install -eq "y") {
        Write-Host ""
        Write-Host "Installing WSL... This will take a few minutes." -ForegroundColor Green
        Write-Host ""

        try {
            Start-Process wsl -ArgumentList "--install" -Verb RunAs -Wait

            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "  WSL Installation Complete!" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "IMPORTANT: You must RESTART YOUR COMPUTER now." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "After restarting:" -ForegroundColor Cyan
            Write-Host "1. Open PowerShell or Command Prompt"
            Write-Host "2. Run: .\start.ps1  (or start.bat)"
            Write-Host ""

            Read-Host "Press Enter to exit"
            exit 0
        } catch {
            Write-Host ""
            Write-Host "Installation failed or was cancelled." -ForegroundColor Red
            Write-Host ""
            Write-Host "Please install WSL manually:" -ForegroundColor Yellow
            Write-Host "1. Open PowerShell as Administrator"
            Write-Host "2. Run: wsl --install"
            Write-Host "3. Restart your computer"
            Write-Host ""
            Write-Host "For more info: https://aka.ms/wsl" -ForegroundColor Cyan
            Write-Host ""

            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        Write-Host ""
        Write-Host "Manual Installation Instructions:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Open PowerShell as Administrator"
        Write-Host "2. Run: wsl --install"
        Write-Host "3. Restart your computer"
        Write-Host "4. Run this script again"
        Write-Host ""
        Write-Host "For more info: https://aka.ms/wsl" -ForegroundColor Cyan
        Write-Host ""

        Read-Host "Press Enter to exit"
        exit 1
    }
}

# WSL is installed, check for distribution
$distributions = wsl --list --quiet 2>&1 | Where-Object { $_ -ne "" }
if ($distributions.Count -eq 0) {
    Write-Host "WSL is installed but no Linux distribution found." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Installing Ubuntu (this is quick)..." -ForegroundColor Green
    Write-Host ""

    wsl --install -d Ubuntu

    Write-Host ""
    Write-Host "Ubuntu installed! Setting up Agent Flywheel..." -ForegroundColor Green
    Write-Host ""
}

# Get current directory and convert to WSL path
$winDir = Get-Location
$wslDir = wsl wslpath -a "$winDir"

Write-Host "Starting Agent Flywheel in WSL..." -ForegroundColor Green
Write-Host ""

# Check if project directory is accessible
$dirCheck = wsl test -d "$wslDir" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Project directory not accessible from WSL" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this script from the agent-flywheel directory:" -ForegroundColor Yellow
    Write-Host "  cd path\to\agent-flywheel-cross-platform"
    Write-Host "  .\start.ps1"
    Write-Host ""

    Read-Host "Press Enter to exit"
    exit 1
}

# First time setup check
$installScript = wsl test -f "$wslDir/install.sh" 2>&1
if ($LASTEXITCODE -eq 0) {
    $installComplete = wsl test -f "$wslDir/.install-complete" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "First time setup detected." -ForegroundColor Cyan
        Write-Host "Running installer..." -ForegroundColor Cyan
        Write-Host ""

        wsl bash -c "cd '$wslDir' && chmod +x install.sh && ./install.sh"

        if ($LASTEXITCODE -eq 0) {
            wsl touch "$wslDir/.install-complete"
        }

        Write-Host ""
    }
}

# Make scripts executable
wsl bash -c "cd '$wslDir' && chmod +x start setup-fzf.sh scripts/*.sh" 2>$null

# Launch the visual interface
wsl bash -c "cd '$wslDir' && ./start"

Write-Host ""
Write-Host "Agent Flywheel session ended." -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
