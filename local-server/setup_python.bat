@echo off
REM Setup script for Python dependencies on Windows

echo 🐍 Setting up Python environment for VIAS server...

REM Check if Python 3 is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is not installed. Please install Python 3 first.
    pause
    exit /b 1
)

echo ✅ Python found
python --version

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo 📦 Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo 🔄 Activating virtual environment...
call venv\Scripts\activate

REM Upgrade pip
echo ⬆️ Upgrading pip...
pip install --upgrade pip

REM Install required packages
echo 📥 Installing required Python packages...
pip install sentence-transformers
pip install faiss-cpu
pip install numpy
pip install torch
pip install transformers
pip install accelerate

echo ✅ Python setup complete!
echo.
echo 🚀 To run the server:
echo 1. Activate the virtual environment: venv\Scripts\activate
echo 2. Start the server: node index.js
echo.
echo 🧪 To test Python scripts:
echo venv\Scripts\activate
echo echo Test content > pdf_text.txt
echo python python\embed_and_index.py
echo python python\query_faiss.py "What is this about?"

pause
