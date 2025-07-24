// Test script for your new local server
// Run with: node test_server.js

const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const SERVER_URL = 'http://localhost:3000';

async function testServer() {
  console.log('🧪 Testing Local Server...\n');

  // Test 1: Check if server is running
  try {
    console.log('1️⃣ Testing server connectivity...');
    const response = await axios.get(SERVER_URL);
    console.log('✅ Server is running');
  } catch (error) {
    console.log('❌ Server is not running. Start it with: cd local-server && node index.js');
    return;
  }

  // Test 2: Test PDF upload endpoint
  try {
    console.log('\n2️⃣ Testing PDF upload endpoint...');
    
    // Create a simple test file if it doesn't exist
    const testContent = 'This is a test PDF content for testing purposes.';
    if (!fs.existsSync('test.txt')) {
      fs.writeFileSync('test.txt', testContent);
    }

    const form = new FormData();
    form.append('pdf', fs.createReadStream('test.txt'), 'test.pdf');

    const uploadResponse = await axios.post(`${SERVER_URL}/api/upload`, form, {
      headers: form.getHeaders(),
      timeout: 30000
    });

    console.log('✅ PDF upload successful:', uploadResponse.data);
  } catch (error) {
    console.log('❌ PDF upload failed:', error.response?.data || error.message);
  }

  // Test 3: Test question endpoint
  try {
    console.log('\n3️⃣ Testing question endpoint...');
    
    const questionResponse = await axios.post(`${SERVER_URL}/api/ask`, {
      question: 'What is this document about?'
    });

    console.log('✅ Question answered:', questionResponse.data);
  } catch (error) {
    console.log('❌ Question failed:', error.response?.data || error.message);
  }

  console.log('\n🎉 Server testing complete!');
  
  // Clean up test file
  if (fs.existsSync('test.txt')) {
    fs.unlinkSync('test.txt');
  }
}

// Run the test
testServer().catch(console.error);
