// Test if server is accessible from different addresses
const express = require('express');
const app = express();
const port = 3000;

app.use(express.json());

// Test endpoint
app.get('/', (req, res) => {
    console.log(`📥 Request received from: ${req.ip}`);
    res.json({
        message: 'Server is running!',
        timestamp: new Date().toISOString(),
        clientIP: req.ip,
        host: req.get('host')
    });
});

app.post('/api/ask', (req, res) => {
    console.log(`📥 Question received from: ${req.ip}`);
    console.log(`❓ Question: ${req.body.question}`);
    res.json({
        answer: 'Test response from local server',
        timestamp: new Date().toISOString()
    });
});

// Start server on all interfaces (0.0.0.0) so Android emulator can access it
app.listen(port, '0.0.0.0', () => {
    console.log(`🚀 Test server running on:`);
    console.log(`   - http://localhost:${port}`);
    console.log(`   - http://127.0.0.1:${port}`);
    console.log(`   - http://10.0.2.2:${port} (Android emulator)`);
    console.log(`   - http://0.0.0.0:${port} (All interfaces)`);
    console.log('');
    console.log('🧪 Test URLs:');
    console.log(`   curl http://localhost:${port}`);
    console.log(`   curl http://10.0.2.2:${port} # From Android emulator`);
});
