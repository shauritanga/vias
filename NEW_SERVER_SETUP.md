# Flutter App Setup with New Local Server

## 🚀 Quick Start

### 1. Start Your Local Server
```bash
cd local-server
npm install
node index.js
```
Server will run on `http://localhost:3000`

### 2. Update Flutter App Configuration
The Flutter app has been updated to work with your new server structure:

- **Base URL**: Changed to `http://localhost:3000`
- **PDF Upload**: Now uses `/api/upload` with multipart form data
- **Questions**: Now uses `/api/ask` endpoint
- **Removed**: Hugging Face API dependencies

### 3. Test the Integration

#### Upload a PDF:
1. Run your Flutter app
2. Go to admin section
3. Upload a PDF file
4. Check server logs for: `PDF indexed successfully`

#### Ask Questions:
1. Use voice commands or text input
2. Ask questions about the uploaded PDF
3. Server will use Python scripts for AI processing

## 🔧 Current Server Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/upload` | POST | Upload and process PDF |
| `/api/ask` | POST | Ask questions about PDF |

## 📁 Server Structure

```
local-server/
├── index.js              # Main server file
├── controllers/
│   └── pdfController.js   # PDF handling logic
├── routes/
│   └── pdfRoutes.js       # API routes
├── services/
│   ├── pdfParser.js       # PDF text extraction
│   ├── pythonService.js   # Python script runner
│   └── python/            # Python AI scripts
└── uploads/               # Uploaded files
```

## 🐍 Python Dependencies

Make sure you have these Python packages installed:
```bash
pip install faiss-cpu sentence-transformers numpy
```

## 🔍 Troubleshooting

### Server Issues:
- Check if Python3 is installed: `python3 --version`
- Verify Python packages: `pip list`
- Check server logs for errors

### Flutter App Issues:
- Make sure server is running on port 3000
- Check Flutter debug logs for connection errors
- Verify baseUrl in `vercel_backend_service.dart`

## 🚧 Missing Features

Your new server doesn't have these features yet:
- Language switching (English/Swahili)
- PDF summarization
- Command logging
- Health check endpoint

Would you like me to help add any of these features?
