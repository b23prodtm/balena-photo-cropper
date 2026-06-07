@echo off
SETLOCAL EnableDelayedExpansion

:: Move to the directory where this batch file is located
cd /d "%~dp0"
:: Go up one level to the project root
cd ..

SET "VENV_DIR=%CD%\venv_win"

:: 1. Check if Python is installed on Windows
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in your Windows PATH.
    echo Please install Python from python.org and try again.
    pause
    exit /b 1
)

:: 2. Setup Windows Virtual Environment if it doesn't exist
if not exist "%VENV_DIR%" (
    echo --> [Windows] Creating virtual environment at %VENV_DIR%...
    python -m venv "%VENV_DIR%"
)

echo --> [Windows] Installing pip dependencies (opencv, numpy)...
"%VENV_DIR%\Scripts\pip" install --upgrade pip
"%VENV_DIR%\Scripts\pip" install -r "tools\requirements.txt"
:: 3. Run the python script using the Windows venv interpreter
echo --> [Windows] Launching Interactive Cropper...
"%VENV_DIR%\Scripts\python" "tools\interactive_cropper.py"

if %errorlevel% neq 0 (
    echo [ERROR] Script exited with an error.
    pause
)