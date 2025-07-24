#!/bin/bash
# Setup script for Python dependencies

echo "🐍 Setting up Python environment for VIAS server..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip

# Install required packages
echo "📥 Installing required Python packages..."
pip install sentence-transformers
pip install faiss-cpu
pip install numpy
pip install torch
pip install transformers
pip install accelerate

echo "✅ Python setup complete!"
echo ""
echo "🚀 To run the server:"
echo "1. Activate the virtual environment: source venv/bin/activate"
echo "2. Start the server: node index.js"
echo ""
echo "🧪 To test Python scripts:"
echo "source venv/bin/activate"
echo "echo 'Test content' > pdf_text.txt"
echo "python python/embed_and_index.py"
echo "python python/query_faiss.py 'What is this about?'"
