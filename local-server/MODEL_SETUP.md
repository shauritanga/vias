# AI Model Setup Guide

## 🚀 Quick Setup (Recommended)

### Option 1: One-Command Setup

```bash
cd local-server
npm run setup
```

This will:

- Install Node.js dependencies
- Download and cache all AI models
- Verify everything is working

### Option 2: Step-by-Step Setup

```bash
cd local-server

# 1. Install Node.js dependencies
npm install

# 2. Activate Python virtual environment
source venv/bin/activate

# 3. Download AI models
npm run download-models
# or directly: python3 python/download_models.py
```

## 🔍 Check Model Status

To see if models are already cached:

```bash
npm run check-models
```

## 📦 Models That Will Be Downloaded

1. **SentenceTransformer**: `all-MiniLM-L6-v2` (~90MB)
   - Used for text embeddings and semantic search
   - Fast and lightweight

2. **Question-Answering**: `distilbert-base-cased-distilled-squad` (~250MB)
   - Used for answering questions about PDF content
   - Optimized for speed

3. **Summarization**: `facebook/bart-large-cnn` (~560MB)
   - Used for generating PDF summaries
   - High-quality abstractive summarization

## ⏱️ Expected Download Times

- **First time**: 3-8 minutes (downloading ~900MB total)
- **Subsequent runs**: Instant (models are cached)

## 🎯 Benefits of Pre-downloading

✅ **Faster responses** - No waiting for model downloads during questions  
✅ **Better user experience** - Immediate answers  
✅ **Offline capability** - Models work without internet after download  
✅ **Predictable performance** - No surprise delays  

## 🧪 Test the Setup

After downloading models, test them:

```bash
cd local-server
source venv/bin/activate

# Test with a simple question
echo "This is a test document about university programs." > pdf_text.txt
python3 python/embed_and_index.py
python3 python/query_faiss.py "What is this about?"
```

## 🔧 Troubleshooting

### Models not downloading?

```bash
# Check Python environment
source venv/bin/activate
pip list | grep -E "(transformers|sentence-transformers|torch)"

# Manual download
python3 python/download_models.py
```

### Still slow responses?

- Check if virtual environment is activated
- Verify models are cached: `npm run check-models`
- Check available disk space (models need ~500MB)

## 📁 Where Models Are Stored

Models are cached in:

- **macOS/Linux**: `~/.cache/huggingface/`
- **Windows**: `%USERPROFILE%\.cache\huggingface\`

You can safely delete this folder to re-download models if needed.

## 🚀 Start Your Server

After setup:

```bash
npm start
```

Your server will be ready for fast question answering!
