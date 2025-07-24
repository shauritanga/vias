# Render.com Deployment Guide

## 🚀 Deploy with Pre-Downloaded Models

### Option 1: Build-Time Download (Recommended)

1. **Update your Render service settings**:
   - **Build Command**: `npm run build`
   - **Start Command**: `npm start`

2. **The build process will**:
   - Install Node.js dependencies
   - Install Python dependencies
   - Download all AI models (~900MB)
   - Cache them for fast startup

### Option 2: Custom Build Script

1. **Set Render build command to**: `./render-build.sh`
2. **Make sure the script is executable**:
   ```bash
   chmod +x render-build.sh
   git add render-build.sh
   git commit -m "Add Render build script"
   git push
   ```

### Option 3: Runtime Download (Fallback)

If build-time download fails, the server will:
- Check for cached models on startup
- Download missing models in background
- Show progress in logs

## 📊 Render Resource Requirements

### Recommended Plan:
- **Starter Plan** ($7/month) or higher
- **RAM**: 512MB minimum (models need ~400MB)
- **Storage**: 2GB+ (models are ~900MB)
- **Build time**: Allow 10-15 minutes for first deployment

### Free Tier Limitations:
- ⚠️ May timeout during model download (15min limit)
- ⚠️ Limited storage may not fit all models
- ⚠️ Cold starts will be slower

## 🔧 Environment Variables

Set these in your Render dashboard:

```
NODE_ENV=production
PYTHON_PATH=/opt/render/project/src/venv/bin/python3
```

## 📦 What Gets Downloaded

During deployment, these models are cached:

1. **SentenceTransformer** (~90MB)
2. **Question-Answering** (~250MB) 
3. **Summarization** (~560MB)

**Total**: ~900MB cached in `/opt/render/project/src/.cache/`

## 🚀 Deployment Steps

1. **Push your code**:
   ```bash
   git add .
   git commit -m "Add AI model pre-download"
   git push
   ```

2. **Render will**:
   - Run `npm run build`
   - Download all models
   - Start your server

3. **Check logs** for:
   ```
   📚 Downloading SentenceTransformer model...
   ✅ SentenceTransformer model downloaded and cached
   🤖 Downloading Question-Answering model...
   ✅ Question-Answering model downloaded and cached
   📄 Downloading Summarization model...
   ✅ Summarization model downloaded and cached
   🎉 All models downloaded and cached successfully!
   ```

## 🔍 Troubleshooting

### Build Timeout?
- Upgrade to Starter plan for longer build times
- Or use runtime download (slower first responses)

### Out of Memory?
- Upgrade to plan with more RAM
- Models need ~400MB RAM to load

### Models Not Downloading?
Check logs for:
```bash
# In Render logs
pip list | grep transformers
python3 python/download_models.py
```

## ✅ Verification

After deployment, test:
1. Upload a PDF
2. Ask a question - should respond quickly
3. Request a summary - should generate AI summary

## 🎯 Benefits on Render

✅ **Fast responses** - Models pre-cached  
✅ **No cold start delays** - Ready immediately  
✅ **Persistent cache** - Models stay cached between deploys  
✅ **Better user experience** - No waiting for downloads  

Your Render deployment will have all AI models ready for instant responses!
