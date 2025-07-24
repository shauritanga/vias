#!/bin/bash

echo "🧪 Testing Render Server Fixes"
echo "================================"
echo ""

# Test 1: Quick Response (should work immediately)
echo "🚀 Test 1: Quick Response - 'test'"
echo "Expected: Fast response (<2 seconds)"
echo ""

start_time=$(date +%s)
response=$(curl -s -X POST https://vias.onrender.com/api/answer-question \
  -H "Content-Type: application/json" \
  -d '{"question": "test", "history": []}' \
  --max-time 30)
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "⏱️  Response time: ${duration} seconds"
echo "📝 Response: $response"
echo ""

if [[ $response == *"success\":true"* ]]; then
  echo "✅ Test 1 PASSED - Quick response working"
else
  echo "❌ Test 1 FAILED - Quick response not working"
fi

echo ""
echo "================================"
echo ""

# Test 2: Simple Question (may use AI or fallback)
echo "🚀 Test 2: Simple Question - 'hello'"
echo "Expected: Fast response or graceful fallback"
echo ""

start_time=$(date +%s)
response=$(curl -s -X POST https://vias.onrender.com/api/answer-question \
  -H "Content-Type: application/json" \
  -d '{"question": "hello", "history": []}' \
  --max-time 30)
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "⏱️  Response time: ${duration} seconds"
echo "📝 Response: $response"
echo ""

if [[ $response == *"success\":true"* ]]; then
  echo "✅ Test 2 PASSED - Server responding"
else
  echo "❌ Test 2 FAILED - Server not responding properly"
fi

echo ""
echo "================================"
echo ""

# Test 3: Complex Question (will test fallback system)
echo "🚀 Test 3: Complex Question - 'what programs are offered'"
echo "Expected: AI response or text-only fallback"
echo ""

start_time=$(date +%s)
response=$(curl -s -X POST https://vias.onrender.com/api/answer-question \
  -H "Content-Type: application/json" \
  -d '{"question": "what programs are offered", "history": []}' \
  --max-time 30)
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "⏱️  Response time: ${duration} seconds"
echo "📝 Response: $response"
echo ""

if [[ $response == *"success\":true"* ]]; then
  echo "✅ Test 3 PASSED - Complex question handled"
elif [[ $response == *"error"* ]]; then
  echo "⚠️  Test 3 PARTIAL - Got error response (but server responded)"
else
  echo "❌ Test 3 FAILED - No response from server"
fi

echo ""
echo "🎯 SUMMARY"
echo "================================"
echo "The server should now:"
echo "• Respond to quick questions immediately"
echo "• Handle AI model failures gracefully"
echo "• Provide text-only fallbacks when AI fails"
echo "• Never hang without responding"
echo ""
echo "Check Render logs for detailed debugging info!"
