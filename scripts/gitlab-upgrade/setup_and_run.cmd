@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo GitLab Upgrade - Environment Setup
echo ============================================================
echo.

REM Check if venv exists
if not exist ".venv\" (
    echo Creating virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo ERROR: Failed to create virtual environment
        exit /b 1
    )
    echo Virtual environment created successfully
    echo.
) else (
    echo Virtual environment already exists
    echo.
)

REM Activate venv
echo Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment
    exit /b 1
)
echo.

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip --quiet
if errorlevel 1 (
    echo WARNING: Failed to upgrade pip
) else (
    echo pip upgraded successfully
)
echo.

REM Install/upgrade requirements
if exist "requirements.txt" (
    echo Installing requirements...
    pip install -r requirements.txt --quiet
    if errorlevel 1 (
        echo ERROR: Failed to install requirements
        echo.
        echo Troubleshooting:
        echo   1. Check requirements.txt format
        echo   2. Try manually: .venv\Scripts\python.exe -m pip install -r requirements.txt
        echo   3. Check network connectivity / proxy settings
        exit /b 1
    )
    echo Requirements installed successfully
    echo.
) else (
    echo WARNING: requirements.txt not found
    echo Expected: boto3~=1.42, paramiko~=4.0, requests~=2.32
    echo.
    set /p continue="Continue anyway? (y/n): "
    if /i not "!continue!"=="y" (
        echo Aborted by user
        exit /b 1
    )
)

REM Run the upgrade script
echo ============================================================
echo Starting GitLab Upgrade Script
echo ============================================================
echo.

python upgrade.py
set EXIT_CODE=%errorlevel%

REM Deactivate venv
call .venv\Scripts\deactivate.bat 2>nul

exit /b %EXIT_CODE%
