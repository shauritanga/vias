// Vercel API Route: /api/process-pdf.js
// Processes uploaded PDF and extracts text

import formidable from 'formidable';
import fs from 'fs';
import pdfParse from 'pdf-parse';

// Disable body parser for file uploads
export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Parse the uploaded file
    const form = formidable({
      maxFileSize: 10 * 1024 * 1024, // 10MB limit
      filter: ({ mimetype }) => mimetype && mimetype.includes('pdf'),
    });

    const [fields, files] = await form.parse(req);
    const file = files.pdf?.[0];

    if (!file) {
      return res.status(400).json({ error: 'No PDF file uploaded' });
    }

    // Read and parse PDF
    const dataBuffer = fs.readFileSync(file.filepath);
    const pdfData = await pdfParse(dataBuffer);
    const text = pdfData.text;

    // Split into pages
    const pages = text.split('\f').filter(page => page.trim().length > 0);

    // Create chunks for processing
    const chunks = pages.map((page, index) => ({
      id: `page_${index + 1}`,
      page: index + 1,
      text: page.trim(),
      status: 'pending',
      tag: 'Uncategorized',
      timestamp: new Date().toISOString(),
    }));

    // Clean up temp file
    fs.unlinkSync(file.filepath);

    // Return processed chunks
    res.status(200).json({
      success: true,
      message: `PDF processed successfully. Extracted ${chunks.length} pages.`,
      chunks: chunks,
      totalPages: chunks.length,
    });

  } catch (error) {
    console.error('PDF processing error:', error);
    res.status(500).json({ 
      error: 'Failed to process PDF',
      details: error.message 
    });
  }
}
