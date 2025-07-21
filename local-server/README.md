# VIAS DIT Server - Free Cloud Hosting

## 🚀 Deploy to Render (100% FREE)

### Step 1: Push to GitHub
```bash
# In your project root
git add .
git commit -m "Prepare server for Render deployment"
git push origin main
```

### Step 2: Deploy on Render
1. Go to [render.com](https://render.com)
2. Sign up with GitHub (FREE - no credit card needed)
3. Click "New +" → "Web Service"
4. Connect your GitHub repository
5. Select the `local-server` folder as root directory
6. Use these settings:
   - **Name**: `vias-dit-server`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: `Free`

### Step 3: Add Environment Variable
In Render dashboard:
1. Go to your service → "Environment"
2. Add: `HUGGING_FACE_API_KEY` = `your_hugging_face_token`

### Step 4: Update Flutter App
Update `lib/core/services/vercel_backend_service.dart`:
```dart
static const String baseUrl = 'https://your-app-name.onrender.com';
```

## 🌟 Features
- ✅ **100% FREE** hosting
- ✅ **Automatic HTTPS**
- ✅ **Swahili & English** support
- ✅ **PDF processing** with Hugging Face AI
- ✅ **Voice-optimized** responses
- ✅ **No credit card** required

## 🔧 Local Development
```bash
npm install
npm start
# Server runs on http://localhost:10000
```

## 📱 API Endpoints
- `POST /api/process-pdf` - Upload and process PDF
- `POST /api/answer-question` - Ask questions in English/Swahili
- `POST /api/summarize-pdf` - Get PDF summary
- `GET/POST /api/language` - Language switching
- `GET /` - Health check

## 🌍 Language Support
- **English**: Default language
- **Swahili**: Full translation support
- **Voice Commands**: 
  - "Change language to Swahili"
  - "Badilisha lugha kuwa Kiingereza"

## 🤗 AI Provider
Uses **Hugging Face** (completely free):
- RoBERTa for Q&A
- BART for summarization
- No OpenAI API key needed
