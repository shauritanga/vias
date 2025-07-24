#!/bin/bash
# Test script to verify IP connectivity

echo "🧪 Testing server connectivity with IP address..."

IP="192.168.1.194"
PORT="3000"

echo "🔍 Testing connection to http://${IP}:${PORT}"

# Test if server is reachable
if curl -s --connect-timeout 5 "http://${IP}:${PORT}" > /dev/null; then
    echo "✅ Server is reachable at http://${IP}:${PORT}"
    
    # Test the API endpoint
    echo "🧪 Testing /api/ask endpoint..."
    curl -X POST "http://${IP}:${PORT}/api/ask" \
         -H "Content-Type: application/json" \
         -d '{"question":"test connection"}' \
         --connect-timeout 10
    echo ""
    echo "✅ API test complete"
else
    echo "❌ Server is not reachable at http://${IP}:${PORT}"
    echo "💡 Make sure your server is running with: node index.js"
fi

echo ""
echo "📱 Flutter app should now use: http://${IP}:${PORT}"
