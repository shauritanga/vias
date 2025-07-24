#!/bin/bash
# Render.com build script
# This runs during deployment to set up the server

echo "🚀 Starting Render build process..."

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Set up Python environment
echo "🐍 Setting up Python environment..."

# Install Python dependencies
echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

# Download AI models
echo "🤖 Downloading AI models..."
echo "This may take 5-10 minutes on first deployment..."

python3 python/download_models.py

if [ $? -eq 0 ]; then
    echo "✅ All models downloaded successfully!"
else
    echo "⚠️ Some models failed to download, but continuing..."
    echo "Models will be downloaded on first use (may cause delays)"
fi

echo "🎉 Render build complete!"
echo "Server is ready to start"
