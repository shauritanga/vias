// Test PDF upload functionality
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const SERVER_URL = 'http://localhost:3000';

async function createTestPDF() {
    // Create a simple text file to simulate PDF
    const testContent = `
University Prospectus 2024

PROGRAMS OFFERED:
1. Bachelor of Computer Science - 4 years
   - Programming fundamentals
   - Data structures and algorithms
   - Software engineering
   - Database systems

2. Bachelor of Information Technology - 4 years
   - Network administration
   - System analysis
   - Web development
   - Cybersecurity

ADMISSION REQUIREMENTS:
- High school diploma or equivalent
- Minimum GPA of 3.0
- English proficiency test
- Mathematics placement exam

FEES:
- Tuition: $15,000 per year
- Registration: $500
- Laboratory fees: $300 per semester
- Books and materials: $800 per year

CONTACT INFORMATION:
Email: admissions@university.edu
Phone: (555) 123-4567
Address: 123 University Ave, Education City
`;

    fs.writeFileSync('test_document.txt', testContent);
    console.log('✅ Created test document');
}

async function testPDFUpload() {
    try {
        console.log('🧪 Testing PDF upload...\n');

        // Create test file
        await createTestPDF();

        // Create form data
        const form = new FormData();
        form.append('pdf', fs.createReadStream('test_document.txt'), {
            filename: 'test_prospectus.pdf',
            contentType: 'application/pdf'
        });

        console.log('📤 Uploading test document...');
        const response = await axios.post(`${SERVER_URL}/api/upload`, form, {
            headers: {
                ...form.getHeaders(),
            },
            timeout: 60000 // 60 second timeout
        });

        console.log('✅ Upload successful!');
        console.log('📊 Response:', JSON.stringify(response.data, null, 2));

        // Test question answering
        console.log('\n🤔 Testing question answering...');
        const questionResponse = await axios.post(`${SERVER_URL}/api/ask`, {
            question: 'What programs are offered?'
        });

        console.log('✅ Question answered!');
        console.log('💡 Answer:', questionResponse.data.answer);

        // Clean up
        fs.unlinkSync('test_document.txt');
        console.log('\n🧹 Cleaned up test files');
        console.log('🎉 All tests passed!');

    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        
        // Clean up on error
        try {
            fs.unlinkSync('test_document.txt');
        } catch (cleanupError) {
            // Ignore cleanup errors
        }
    }
}

// Run the test
console.log('🚀 Starting PDF upload test...');
testPDFUpload();
