@echo off
setlocal

cls

REM Get the name of the current directory
for %%I in (.) do set venv_prompt=%%~nxI

REM Check if .venv exists
if not exist ".venv\" (
    echo Creating virtual environment...
    python -m venv .venv --prompt %venv_prompt%
    call .venv\Scripts\activate
    echo Updating pip and setuptools
    python -m pip install --upgrade pip setuptools
    echo Installing dependencies...
    if exist local-requirements.txt (
        pip install -r local-requirements.txt
    ) else (
        echo No local-requirements.txt found. Skipping package installation.
    )
) else (
    echo Virtual environment found.
    call .venv\Scripts\activate
    echo Updating pip and setuptools
    python -m pip install --upgrade pip setuptools
    echo Updating dependencies...
    if exist local-requirements.txt (
        pip install --upgrade -r local-requirements.txt
    ) else (
        echo No local-requirements.txt found. Skipping package update.
    )
)

cmd /k

endlocal
