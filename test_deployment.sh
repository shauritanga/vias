#!/bin/bash

# Test script for VIAS server deployment
echo "🧪 Testing VIAS Server Deployment"
echo "=================================="

# Replace with your actual Render URL
SERVER_URL="https://your-app-name.onrender.com"

echo "🌐 Testing server health..."
curl -s "$SERVER_URL/" | head -5

echo ""
echo "🌍 Testing language API..."
curl -s -X GET "$SERVER_URL/api/language" | head -5

echo ""
echo "🎤 Testing language change..."
curl -s -X POST "$SERVER_URL/api/language" \
  -H "Content-Type: application/json" \
  -d '{"language": "swahili"}' | head -5

echo ""
echo "❓ Testing question API..."
curl -s -X POST "$SERVER_URL/api/answer-question" \
  -H "Content-Type: application/json" \
  -d '{"question": "What programs are available?"}' | head -10

echo ""
echo "✅ Deployment test completed!"
echo "📱 Update your Flutter app with: $SERVER_URL"
