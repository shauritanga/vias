# 🚀 VIAS Q&A Server - Render Deployment Guide

Complete guide to deploy your enhanced Q&A system to Render.

## 📋 Pre-Deployment Checklist

### ✅ Files Ready
- [x] `render.yaml` - Render configuration
- [x] `local-server/package.json` - Updated with correct scripts
- [x] `local-server/index.js` - Enhanced server with health checks
- [x] `.gitignore` - Clean repository
- [x] `Dockerfile` - Optional Docker support

### ✅ Environment Setup
- [x] Hugging Face API key obtained
- [x] GitHub repository ready
- [x] Render account created

## 🎯 Step-by-Step Deployment

### Step 1: Prepare Your Repository

1. **Commit all changes:**
   ```bash
   git add .
   git commit -m "Prepare for Render deployment with enhanced Q&A"
   git push origin main
   ```

2. **Verify files are in place:**
   ```bash
   ls -la render.yaml
   ls -la local-server/package.json
   ls -la local-server/index.js
   ```

### Step 2: Deploy to Render

1. **Go to Render Dashboard:**
   - Visit: https://dashboard.render.com
   - Sign in with GitHub

2. **Create New Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Select your VIAS repository

3. **Configure Service:**
   ```
   Name: vias-qa-server
   Environment: Node
   Region: Choose closest to your users
   Branch: main
   Root Directory: (leave empty)
   Build Command: cd local-server && npm install
   Start Command: cd local-server && npm start
   ```

4. **Set Environment Variables:**
   ```
   NODE_ENV=production
   HUGGING_FACE_API_KEY=your_actual_api_key_here
   ```

5. **Choose Plan:**
   - **Free**: Good for testing (sleeps after 15 min)
   - **Starter ($7/month)**: Recommended for production

6. **Deploy:**
   - Click "Create Web Service"
   - Wait for build to complete (5-10 minutes)

### Step 3: Verify Deployment

1. **Check Health:**
   ```bash
   curl https://your-app-name.onrender.com/
   ```

2. **Expected Response:**
   ```json
   {
     "status": "healthy",
     "service": "VIAS Enhanced Q&A Server",
     "version": "2.0.0",
     "features": {
       "huggingFaceAI": true,
       "multiModelSupport": true,
       "semanticSearch": true
     }
   }
   ```

3. **Test Q&A Endpoint:**
   ```bash
   curl -X POST https://your-app-name.onrender.com/api/answer-question \
     -H "Content-Type: application/json" \
     -d '{"question": "What is this service?"}'
   ```

## 🔧 Configuration Details

### Environment Variables Explained

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `NODE_ENV` | Yes | Environment mode | `production` |
| `HUGGING_FACE_API_KEY` | Yes | Your HF API key | `hf_xxxxx...` |
| `PORT` | No | Server port (auto-set) | `10000` |

### Build Process

1. **Install Dependencies:**
   ```bash
   cd local-server && npm install
   ```

2. **Start Server:**
   ```bash
   cd local-server && npm start
   ```

3. **Health Check:**
   - Render monitors `/` endpoint
   - Returns 200 if healthy

## 📊 Monitoring & Maintenance

### Health Monitoring

1. **Basic Health:**
   ```bash
   curl https://your-app.onrender.com/
   ```

2. **Detailed Health:**
   ```bash
   curl https://your-app.onrender.com/api/health
   ```

3. **Response Indicators:**
   ```json
   {
     "checks": {
       "server": "healthy",
       "memory": "healthy",
       "huggingFace": "configured",
       "contentLoaded": "ready"
     }
   }
   ```

### Performance Monitoring

- **Memory Usage**: Check `/api/health` endpoint
- **Response Times**: Monitor via Render dashboard
- **Error Rates**: Check Render logs

### Logs Access

1. **Via Render Dashboard:**
   - Go to your service
   - Click "Logs" tab
   - View real-time logs

2. **Via CLI (optional):**
   ```bash
   # Install Render CLI
   npm install -g @render/cli
   
   # View logs
   render logs -s your-service-id
   ```

## 🚨 Troubleshooting

### Common Issues

1. **Build Fails:**
   ```
   Error: Cannot find module 'express'
   ```
   **Solution:** Check `package.json` dependencies

2. **Health Check Fails:**
   ```
   Error: connect ECONNREFUSED
   ```
   **Solution:** Verify server starts on correct port

3. **API Key Issues:**
   ```
   Error: 401 Unauthorized
   ```
   **Solution:** Check Hugging Face API key in environment variables

4. **Memory Issues:**
   ```
   Error: JavaScript heap out of memory
   ```
   **Solution:** Upgrade to paid plan or optimize memory usage

### Debug Steps

1. **Check Build Logs:**
   - Go to Render dashboard
   - View build logs for errors

2. **Test Locally:**
   ```bash
   cd local-server
   NODE_ENV=production npm start
   ```

3. **Verify Environment:**
   ```bash
   curl https://your-app.onrender.com/api/health
   ```

## 🔄 Updates & Redeployment

### Automatic Deployment

- **Push to main branch** triggers auto-deployment
- **Build time**: 5-10 minutes
- **Zero downtime**: Render handles gracefully

### Manual Deployment

1. **Via Dashboard:**
   - Go to your service
   - Click "Manual Deploy"
   - Select branch and deploy

2. **Force Rebuild:**
   - Clear build cache if needed
   - Useful for dependency issues

## 💰 Cost Optimization

### Free Tier Usage

- **Good for**: Development, testing, demos
- **Limitations**: Sleeps after 15 min, shared resources
- **Cost**: $0/month

### Paid Tier Benefits

- **Always on**: No sleeping
- **Better performance**: Dedicated resources
- **Custom domains**: Professional URLs
- **Cost**: $7+/month

### Optimization Tips

1. **Use efficient models**: Smaller Hugging Face models
2. **Cache responses**: Implement response caching
3. **Monitor usage**: Track API calls and memory
4. **Scale appropriately**: Start small, upgrade as needed

## 🔒 Security Best Practices

1. **Environment Variables:**
   - Never commit API keys to git
   - Use Render's environment variable system

2. **CORS Configuration:**
   - Configure allowed origins
   - Restrict in production

3. **Rate Limiting:**
   - Implement request rate limiting
   - Prevent abuse

4. **Input Validation:**
   - Validate all user inputs
   - Sanitize data

## 📈 Scaling Considerations

### Horizontal Scaling

- **Multiple instances**: Available on paid plans
- **Load balancing**: Automatic with Render
- **Database**: Consider external database for persistence

### Vertical Scaling

- **Memory**: Upgrade plan for more RAM
- **CPU**: Better performance with paid tiers
- **Storage**: Persistent disks for large files

## 🎉 Success Checklist

After deployment, verify:

- [ ] Health endpoint returns 200
- [ ] Q&A endpoint processes questions
- [ ] Hugging Face integration works
- [ ] Logs show no critical errors
- [ ] Response times are acceptable
- [ ] Memory usage is stable

## 📞 Support Resources

- **Render Docs**: https://render.com/docs
- **Hugging Face Docs**: https://huggingface.co/docs
- **Node.js Docs**: https://nodejs.org/docs
- **GitHub Issues**: For project-specific help

---

🎯 **Ready to deploy?** Follow the steps above and your enhanced Q&A system will be live in minutes!
