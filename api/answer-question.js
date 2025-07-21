// Vercel API Route: /api/answer-question.js
// AI-powered Q&A using OpenAI (optional - can work without)

// Simple keyword-based search as fallback
function findRelevantContent(question, contentChunks) {
  const questionWords = question.toLowerCase().split(' ');
  const scoredChunks = [];

  contentChunks.forEach(chunk => {
    let score = 0;
    const chunkText = chunk.text.toLowerCase();
    
    // Simple keyword matching
    questionWords.forEach(word => {
      if (word.length > 3) { // Skip short words
        const matches = (chunkText.match(new RegExp(word, 'g')) || []).length;
        score += matches;
      }
    });

    if (score > 0) {
      scoredChunks.push({ ...chunk, score });
    }
  });

  // Sort by relevance
  scoredChunks.sort((a, b) => b.score - a.score);
  return scoredChunks.slice(0, 3); // Top 3 relevant chunks
}

// Generate simple answer from content
function generateAnswer(question, relevantChunks) {
  if (relevantChunks.length === 0) {
    return "I couldn't find specific information about that in the prospectus. Please try asking about programs, fees, or admission requirements.";
  }

  const context = relevantChunks.map(chunk => chunk.text).join('\n\n');
  
  // Simple answer generation based on question type
  const questionLower = question.toLowerCase();
  
  if (questionLower.includes('fee') || questionLower.includes('cost') || questionLower.includes('price')) {
    return `Based on the prospectus information:\n\n${context}\n\nFor specific fee details, please refer to the complete fee structure in the prospectus.`;
  }
  
  if (questionLower.includes('admission') || questionLower.includes('requirement') || questionLower.includes('entry')) {
    return `Here are the admission requirements I found:\n\n${context}\n\nPlease verify these requirements with the admissions office.`;
  }
  
  if (questionLower.includes('program') || questionLower.includes('course') || questionLower.includes('degree')) {
    return `Here's information about the programs:\n\n${context}\n\nFor complete program details, please refer to the full prospectus.`;
  }
  
  // Default response
  return `Based on the prospectus content:\n\n${context}`;
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { question, contentChunks } = req.body;

    if (!question) {
      return res.status(400).json({ error: 'Question is required' });
    }

    if (!contentChunks || !Array.isArray(contentChunks)) {
      return res.status(400).json({ error: 'Content chunks are required' });
    }

    // Find relevant content
    const relevantChunks = findRelevantContent(question, contentChunks);
    
    // Generate answer
    const answer = generateAnswer(question, relevantChunks);

    res.status(200).json({
      success: true,
      question: question,
      answer: answer,
      relevantChunks: relevantChunks.length,
      sources: relevantChunks.map(chunk => ({
        page: chunk.page,
        score: chunk.score
      }))
    });

  } catch (error) {
    console.error('Q&A error:', error);
    res.status(500).json({ 
      error: 'Failed to process question',
      details: error.message 
    });
  }
}
