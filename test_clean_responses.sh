#!/bin/bash

echo "🧪 Testing Clean Response Format"
echo "================================"
echo ""

# Test 1: Quick Response
echo "Test 1: Quick Response"
echo "Question: 'test'"
echo "Expected: Simple 'Working.' response"
echo ""

response=$(curl -s -X POST https://vias.onrender.com/api/answer-question \
  -H "Content-Type: application/json" \
  -d '{"question": "test", "history": []}' \
  --max-time 10)

echo "Response: $response"
echo ""

# Check if response contains unwanted verbose elements
if [[ $response == *"smile"* ]] || [[ $response == *"emoji"* ]] || [[ $response == *"Hugging Face"* ]] || [[ $response == *"validation"* ]] || [[ $response == *"generated"* ]]; then
  echo "❌ FAILED - Response still contains verbose elements"
else
  echo "✅ PASSED - Response is clean"
fi

echo ""
echo "================================"
echo ""

# Test 2: Hello Response
echo "Test 2: Greeting Response"
echo "Question: 'hello'"
echo "Expected: Simple greeting without technical details"
echo ""

response=$(curl -s -X POST https://vias.onrender.com/api/answer-question \
  -H "Content-Type: application/json" \
  -d '{"question": "hello", "history": []}' \
  --max-time 10)

echo "Response: $response"
echo ""

# Check if response is clean
if [[ $response == *"smile"* ]] || [[ $response == *"🤗"* ]] || [[ $response == *"AI"* ]] || [[ $response == *"model"* ]]; then
  echo "❌ FAILED - Response contains unwanted elements"
else
  echo "✅ PASSED - Response is clean"
fi

echo ""
echo "🎯 SUMMARY"
echo "================================"
echo "Responses should now be:"
echo "• Direct and simple"
echo "• No emojis or technical jargon"
echo "• No 'generated by' or validation messages"
echo "• Just the answer or 'Unable to find information'"
