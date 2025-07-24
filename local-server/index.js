// VIAS Local Server with OpenAI Integration
// Professional conversational AI for PDF-based Q&A
// Run with: node server.js

require('dotenv').config();
const express = require('express');
const multer = require('multer');
const pdfParse = require('pdf-parse');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const app = express();
const port = process.env.PORT || 10000; // Use Render's port or fallback

// Hugging Face configuration (ONLY AI provider)
const HUGGING_FACE_API_KEY = process.env.HUGGING_FACE_API_KEY;
const HF_API_URL = 'https://api-inference.huggingface.co/models';

// Debug: Log environment variable status
console.log('🔍 Environment check:');
console.log('- NODE_ENV:', process.env.NODE_ENV);
console.log('- HUGGING_FACE_API_KEY exists:', !!HUGGING_FACE_API_KEY);
console.log('- HUGGING_FACE_API_KEY starts with hf_:', HUGGING_FACE_API_KEY?.startsWith('hf_'));

// Validate Hugging Face API key
if (!HUGGING_FACE_API_KEY || HUGGING_FACE_API_KEY.trim() === '') {
  console.error('❌ ERROR: HUGGING_FACE_API_KEY not found in environment variables');
  console.error('Please add your Hugging Face API key to Render environment variables');
  console.error('Get your free API key from: https://huggingface.co/settings/tokens');
  process.exit(1);
}

if (!HUGGING_FACE_API_KEY.startsWith('hf_')) {
  console.error('❌ ERROR: Invalid Hugging Face API key format');
  console.error('API key should start with "hf_"');
  process.exit(1);
}

console.log('✅ Hugging Face API key loaded successfully');

console.log('🤗 AI Provider: HUGGING FACE (FREE)');
console.log('✅ Hugging Face API key loaded successfully');

// Middleware with comprehensive CORS for Flutter web
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests from any localhost port (Flutter web uses random ports)
    if (!origin || origin.startsWith('http://localhost:') || origin.startsWith('https://localhost:')) {
      callback(null, true);
    } else {
      callback(null, true); // Allow all origins for development
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  credentials: true,
  optionsSuccessStatus: 200 // For legacy browser support
}));

// Additional CORS headers for preflight requests
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', req.headers.origin || '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin');
  res.header('Access-Control-Allow-Credentials', 'true');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  next();
});
app.use(express.json({ limit: '10mb' }));

// Create uploads directory
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}

// Configure multer for file uploads
const upload = multer({
  dest: uploadsDir,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files allowed'));
    }
  }
});

// Store processed content in memory (in production, use a database)
let processedContent = [];
let currentLanguage = 'english'; // Default language: 'english' or 'swahili'

// Language translations
const translations = {
  english: {
    noContent: "No PDF content has been uploaded yet. Please upload a prospectus PDF first through the admin dashboard to enable question and answer functionality.",
    noQuestion: "Please ask a question about the prospectus.",
    notAnswerable: "I couldn't find specific information about \"{question}\" in the uploaded prospectus.\n\nThe document contains information about:\n• Academic programs and courses\n• Admission requirements\n• Fees and financial information\n• Campus facilities and services\n• Contact information\n\nPlease try asking about one of these topics, or contact DIT directly at +255-22-2150174 for more information.\n\n💡 **Tip**: Try asking \"What programs are available?\" or \"What are the fees?\"\n\n🤗 **Powered by**: Enhanced content analysis (free service)",
    programsIntro: "DIT University offers the following programs:",
    feesIntro: "Here are the fees at DIT University:",
    feesNote: "Note: Fees may vary by program level and campus. Contact DIT directly for the most current fee structure.",
    feesNotFound: "I found the DIT prospectus but couldn't locate specific fee amounts in the current content.\n\nBased on the document structure, DIT offers programs at different levels:\n- Certificate programs (NTA Level 4)\n- Diploma programs (NTA Level 6)\n- Bachelor's degrees (NTA Level 8)\n- Master's programs (NTA Level 9)\n\nFor detailed fee information, please:\n1. Contact DIT directly at +255-22-2150174\n2. Email: info@dit.ac.tz\n3. Visit: www.dit.ac.tz\n4. Check Chapter 4 \"FEES AND OTHER FINANCIAL REQUIREMENTS\" in the full prospectus\n\nThe document mentions that fees vary by program level and may include additional costs for accommodation, medical insurance (TSh 50,400 per year), and other services.",
    campusInfo: "DIT has multiple campuses including Dar es Salaam (main), Mwanza, and Myunga campuses offering various levels from certificates to master's degrees.",
    languageChanged: "Language changed to English. I will now respond in English.",
    languageHelp: "Available commands:\n• \"Change language to Swahili\" - Switch to Swahili\n• \"Change language to English\" - Switch to English"
  },
  swahili: {
    noContent: "Hakuna maudhui ya PDF yaliyopakiwa bado. Tafadhali pakia PDF ya prospektasi kwanza kupitia dashibodi ya msimamizi ili kuwezesha utendaji wa maswali na majibu.",
    noQuestion: "Tafadhali uliza swali kuhusu prospektasi.",
    notAnswerable: "Sikuweza kupata maelezo maalum kuhusu \"{question}\" katika prospektasi iliyopakiwa.\n\nHati hii ina maelezo kuhusu:\n• Mipango ya kitaaluma na kozi\n• Mahitaji ya kujiunga\n• Ada na maelezo ya kifedha\n• Vifaa vya kampu na huduma\n• Maelezo ya mawasiliano\n\nTafadhali jaribu kuuliza kuhusu moja ya mada hizi, au wasiliana na DIT moja kwa moja kwa +255-22-2150174 kwa maelezo zaidi.\n\n💡 **Kidokezo**: Jaribu kuuliza \"Ni mipango gani inayopatikana?\" au \"Ada ni ngapi?\"\n\n🤗 **Inaendeshwa na**: Uchambuzi wa maudhui ulioboreshwa (huduma ya bure)",
    programsIntro: "Chuo Kikuu cha DIT kinatoa mipango ifuatayo:",
    feesIntro: "Hapa kuna ada za Chuo Kikuu cha DIT:",
    feesNote: "Kumbuka: Ada zinaweza kutofautiana kulingana na kiwango cha mpango na kampu. Wasiliana na DIT moja kwa moja kwa muundo wa ada wa sasa.",
    feesNotFound: "Nimepata prospektasi ya DIT lakini sikuweza kupata kiasi maalum cha ada katika maudhui ya sasa.\n\nKulingana na muundo wa hati, DIT inatoa mipango katika viwango tofauti:\n- Mipango ya vyeti (Kiwango cha NTA 4)\n- Mipango ya diploma (Kiwango cha NTA 6)\n- Shahada za kwanza (Kiwango cha NTA 8)\n- Mipango ya uzamili (Kiwango cha NTA 9)\n\nKwa maelezo ya kina ya ada, tafadhali:\n1. Wasiliana na DIT moja kwa moja kwa +255-22-2150174\n2. Barua pepe: info@dit.ac.tz\n3. Tembelea: www.dit.ac.tz\n4. Angalia Sura ya 4 \"ADA NA MAHITAJI MENGINE YA KIFEDHA\" katika prospektasi kamili\n\nHati inasema kuwa ada zinatofautiana kulingana na kiwango cha mpango na zinaweza kujumuisha gharama za ziada za malazi, bima ya matibabu (TSh 50,400 kwa mwaka), na huduma zingine.",
    campusInfo: "DIT ina kampu nyingi ikiwa ni pamoja na Dar es Salaam (kuu), Mwanza, na kampu za Myunga zinazotoa viwango mbalimbali kutoka vyeti hadi shahada za uzamili.",
    languageChanged: "Lugha imebadilishwa kuwa Kiswahili. Sasa nitajibu kwa Kiswahili.",
    languageHelp: "Amri zinazopatikana:\n• \"Badilisha lugha kuwa Kiswahili\" - Badili kuwa Kiswahili\n• \"Badilisha lugha kuwa Kiingereza\" - Badili kuwa Kiingereza"
  }
};

// Language detection and switching functions
function detectLanguageCommand(question) {
  const lowerQuestion = question.toLowerCase();

  // English language commands
  if (lowerQuestion.includes('change language to swahili') ||
    lowerQuestion.includes('switch to swahili') ||
    lowerQuestion.includes('speak swahili') ||
    lowerQuestion.includes('use swahili')) {
    return 'swahili';
  }

  // Swahili language commands
  if (lowerQuestion.includes('badilisha lugha kuwa kiingereza') ||
    lowerQuestion.includes('badilisha lugha kuwa kingereza') ||
    lowerQuestion.includes('change language to english') ||
    lowerQuestion.includes('switch to english') ||
    lowerQuestion.includes('tumia kiingereza')) {
    return 'english';
  }

  // Help commands
  if (lowerQuestion.includes('language help') ||
    lowerQuestion.includes('lugha') ||
    lowerQuestion.includes('msaada wa lugha')) {
    return 'help';
  }

  return null;
}

function getTranslation(key, replacements = {}) {
  let text = translations[currentLanguage][key] || translations.english[key] || key;

  // Replace placeholders
  Object.keys(replacements).forEach(placeholder => {
    text = text.replace(`{${placeholder}}`, replacements[placeholder]);
  });

  return text;
}

function translateToSwahili(englishText) {
  // Basic translation for common responses
  const commonTranslations = {
    'programs': 'mipango',
    'fees': 'ada',
    'university': 'chuo kikuu',
    'engineering': 'uhandisi',
    'technology': 'teknolojia',
    'bachelor': 'shahada ya kwanza',
    'diploma': 'diploma',
    'certificate': 'cheti',
    'master': 'uzamili',
    'campus': 'kampu',
    'students': 'wanafunzi',
    'admission': 'kujiunga',
    'requirements': 'mahitaji'
  };

  let translatedText = englishText;

  // Apply basic translations
  Object.keys(commonTranslations).forEach(english => {
    const swahili = commonTranslations[english];
    const regex = new RegExp(`\\b${english}\\b`, 'gi');
    translatedText = translatedText.replace(regex, swahili);
  });

  return translatedText;
}

// Enhanced PDF text processing functions
function cleanExtractedText(text) {
  return text
    // Remove excessive whitespace
    .replace(/\s+/g, ' ')
    // Remove page numbers at start of lines
    .replace(/^\d+\s+/gm, '')
    // Remove headers/footers that repeat
    .replace(/^(DIT|UNIVERSITY|PROSPECTUS).*$/gmi, '')
    // Clean up line breaks
    .replace(/\n\s*\n\s*\n/g, '\n\n')
    .trim();
}

function splitByPageMarkers(text) {
  // Try to split by common page markers
  const pageMarkers = [
    /page\s+\d+/gi,
    /^\d+\s*$/gm,
    /---+\s*page\s+\d+\s*---+/gi,
    /\f/g
  ];

  let pages = [text];

  for (const marker of pageMarkers) {
    const newPages = [];
    for (const page of pages) {
      const splits = page.split(marker);
      newPages.push(...splits);
    }
    if (newPages.length > pages.length) {
      pages = newPages;
    }
  }

  return pages.filter(page => page.trim().length > 100);
}

function splitByContentSections(text) {
  // Split by major content sections
  const sectionMarkers = [
    /(?:PROGRAMS?|COURSES?|DEGREES?)\s*(?:OFFERED|AVAILABLE)?/gi,
    /(?:FEE|FEES|TUITION|COST)\s*(?:STRUCTURE|SCHEDULE)?/gi,
    /(?:ADMISSION|ADMISSIONS|ENTRY)\s*(?:REQUIREMENTS?|CRITERIA)?/gi,
    /(?:CONTACT|CONTACTS?)\s*(?:INFORMATION|DETAILS?)?/gi,
    /(?:ABOUT|INTRODUCTION|OVERVIEW)/gi,
    /(?:FACILITIES|INFRASTRUCTURE)/gi,
    /(?:ACADEMIC|CURRICULUM)/gi
  ];

  const sections = [];
  let currentSection = '';
  const lines = text.split('\n');

  for (const line of lines) {
    const isNewSection = sectionMarkers.some(marker => marker.test(line));

    if (isNewSection && currentSection.trim().length > 200) {
      sections.push(currentSection.trim());
      currentSection = line + '\n';
    } else {
      currentSection += line + '\n';
    }
  }

  // Add the last section
  if (currentSection.trim().length > 200) {
    sections.push(currentSection.trim());
  }

  return sections.length > 0 ? sections : [text];
}

function detectContentTag(text) {
  const lowerText = text.toLowerCase();

  if (lowerText.includes('program') || lowerText.includes('course') || lowerText.includes('degree')) {
    return 'Programs';
  } else if (lowerText.includes('fee') || lowerText.includes('cost') || lowerText.includes('tuition')) {
    return 'Fees';
  } else if (lowerText.includes('admission') || lowerText.includes('requirement') || lowerText.includes('entry')) {
    return 'Admissions';
  } else if (lowerText.includes('contact') || lowerText.includes('phone') || lowerText.includes('email')) {
    return 'Contact';
  } else if (lowerText.includes('about') || lowerText.includes('university') || lowerText.includes('institution')) {
    return 'About';
  } else {
    return 'General';
  }
}

// Process large documents (>100 pages) with intelligent chunking
async function processLargeDocument(text, filename, totalPages) {
  console.log('🔍 Analyzing document structure...');

  // First, identify major sections
  const majorSections = identifyMajorSections(text);
  console.log(`📑 Found ${majorSections.length} major sections`);

  let chunks = [];

  // Process each major section
  for (let i = 0; i < majorSections.length; i++) {
    const section = majorSections[i];
    const sectionChunks = processSectionIntoChunks(section, filename, i + 1, totalPages);
    chunks.push(...sectionChunks);
  }

  // If no major sections found, fall back to page-based chunking
  if (chunks.length === 0) {
    console.log('📄 No major sections found, using page-based chunking...');
    chunks = processPageBasedChunking(text, filename, totalPages);
  }

  return chunks;
}

// Process standard documents (<100 pages)
async function processStandardDocument(text, filename, totalPages) {
  const sectionChunks = splitByContentSections(text);

  if (sectionChunks.length > 1) {
    return sectionChunks.map((section, index) => ({
      id: `${filename}_section_${index + 1}`,
      page: Math.floor((index / sectionChunks.length) * totalPages) + 1,
      text: section.trim(),
      status: 'approved',
      tag: detectContentTag(section),
      timestamp: new Date().toISOString(),
      filename: filename,
    }));
  } else {
    return processPageBasedChunking(text, filename, totalPages);
  }
}

// Identify major sections in large documents
function identifyMajorSections(text) {
  const sections = [];
  const lines = text.split('\n');

  // Look for major section headers
  const sectionPatterns = [
    /^(CHAPTER|SECTION|PART)\s+\d+/i,
    /^(UNDERGRADUATE|POSTGRADUATE|GRADUATE)\s+(PROGRAMS?|COURSES?)/i,
    /^(BACHELOR|MASTER|DIPLOMA|CERTIFICATE)\s+(PROGRAMS?|DEGREES?)/i,
    /^(SCHOOL|FACULTY|DEPARTMENT)\s+OF/i,
    /^(ADMISSION|ADMISSIONS?)\s+(REQUIREMENTS?|PROCEDURES?)/i,
    /^(FEE|FEES)\s+(STRUCTURE|SCHEDULE)/i,
    /^(ACADEMIC|CURRICULUM)\s+(PROGRAMS?|STRUCTURE)/i,
    /^(CONTACT|CONTACTS?)\s+(INFORMATION|DETAILS?)/i,
    /^\d+\.\s+(PROGRAMS?|COURSES?|DEGREES?)/i,
  ];

  let currentSection = '';
  let sectionTitle = '';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Check if this line is a major section header
    const isNewSection = sectionPatterns.some(pattern => pattern.test(line));

    if (isNewSection) {
      // Save previous section if it has content
      if (currentSection.trim().length > 500) {
        sections.push({
          title: sectionTitle || 'Section',
          content: currentSection.trim(),
          startLine: Math.max(0, i - currentSection.split('\n').length),
          endLine: i - 1
        });
      }

      // Start new section
      sectionTitle = line;
      currentSection = line + '\n';
    } else {
      currentSection += line + '\n';
    }
  }

  // Add the last section
  if (currentSection.trim().length > 500) {
    sections.push({
      title: sectionTitle || 'Final Section',
      content: currentSection.trim(),
      startLine: lines.length - currentSection.split('\n').length,
      endLine: lines.length - 1
    });
  }

  return sections;
}

// Process a section into smaller chunks
function processSectionIntoChunks(section, filename, sectionIndex, totalPages) {
  const chunks = [];
  const content = section.content;
  const maxChunkSize = 2000; // Characters per chunk

  // If section is small enough, keep as one chunk
  if (content.length <= maxChunkSize) {
    chunks.push({
      id: `${filename}_section_${sectionIndex}`,
      page: Math.floor((section.startLine / totalPages) * totalPages) + 1,
      text: content,
      status: 'approved',
      tag: detectContentTag(content),
      timestamp: new Date().toISOString(),
      filename: filename,
      sectionTitle: section.title
    });
    return chunks;
  }

  // Split large sections into smaller chunks
  const paragraphs = content.split(/\n\s*\n/);
  let currentChunk = '';
  let chunkIndex = 1;

  for (const paragraph of paragraphs) {
    if (currentChunk.length + paragraph.length > maxChunkSize && currentChunk.length > 0) {
      // Save current chunk
      chunks.push({
        id: `${filename}_section_${sectionIndex}_chunk_${chunkIndex}`,
        page: Math.floor((section.startLine / totalPages) * totalPages) + 1,
        text: currentChunk.trim(),
        status: 'approved',
        tag: detectContentTag(currentChunk),
        timestamp: new Date().toISOString(),
        filename: filename,
        sectionTitle: section.title
      });

      currentChunk = paragraph + '\n\n';
      chunkIndex++;
    } else {
      currentChunk += paragraph + '\n\n';
    }
  }

  // Add final chunk
  if (currentChunk.trim().length > 100) {
    chunks.push({
      id: `${filename}_section_${sectionIndex}_chunk_${chunkIndex}`,
      page: Math.floor((section.startLine / totalPages) * totalPages) + 1,
      text: currentChunk.trim(),
      status: 'approved',
      tag: detectContentTag(currentChunk),
      timestamp: new Date().toISOString(),
      filename: filename,
      sectionTitle: section.title
    });
  }

  return chunks;
}

// Process page-based chunking for fallback
function processPageBasedChunking(text, filename, totalPages) {
  const chunks = [];
  const pages = text.split('\f').filter(page => page.trim().length > 100);

  if (pages.length === 0) {
    // If no form feeds, force chunking by size
    const maxChunkSize = 1500; // Smaller chunks for better Q&A

    console.log(`📄 No page breaks found, forcing chunking by ${maxChunkSize} characters`);

    // Split by paragraphs first to maintain context
    const paragraphs = text.split(/\n\s*\n/).filter(p => p.trim().length > 50);

    if (paragraphs.length > 1) {
      // Use paragraph-based chunking
      let currentChunk = '';
      let chunkIndex = 1;

      for (const paragraph of paragraphs) {
        if (currentChunk.length + paragraph.length > maxChunkSize && currentChunk.length > 0) {
          // Save current chunk
          chunks.push({
            id: `${filename}_chunk_${chunkIndex}`,
            page: Math.ceil((chunkIndex / chunks.length) * totalPages) || 1,
            text: currentChunk.trim(),
            status: 'approved',
            tag: detectContentTag(currentChunk),
            timestamp: new Date().toISOString(),
            filename: filename,
          });

          currentChunk = paragraph + '\n\n';
          chunkIndex++;
        } else {
          currentChunk += paragraph + '\n\n';
        }
      }

      // Add final chunk
      if (currentChunk.trim().length > 100) {
        chunks.push({
          id: `${filename}_chunk_${chunkIndex}`,
          page: Math.ceil((chunkIndex / chunks.length) * totalPages) || 1,
          text: currentChunk.trim(),
          status: 'approved',
          tag: detectContentTag(currentChunk),
          timestamp: new Date().toISOString(),
          filename: filename,
        });
      }
    } else {
      // Force split by character count as last resort
      for (let i = 0; i < text.length; i += maxChunkSize) {
        const chunk = text.substring(i, i + maxChunkSize);
        if (chunk.trim().length > 100) {
          chunks.push({
            id: `${filename}_forced_${Math.floor(i / maxChunkSize) + 1}`,
            page: Math.floor(i / maxChunkSize) + 1,
            text: chunk.trim(),
            status: 'approved',
            tag: detectContentTag(chunk),
            timestamp: new Date().toISOString(),
            filename: filename,
          });
        }
      }
    }
  } else {
    // Process actual pages, but split large ones
    pages.forEach((page, index) => {
      if (page.length > 2000) {
        // Split large pages into smaller chunks
        const pageChunks = [];
        for (let i = 0; i < page.length; i += 1500) {
          const chunk = page.substring(i, i + 1500);
          if (chunk.trim().length > 100) {
            pageChunks.push(chunk.trim());
          }
        }

        pageChunks.forEach((chunk, chunkIndex) => {
          chunks.push({
            id: `${filename}_page_${index + 1}_chunk_${chunkIndex + 1}`,
            page: index + 1,
            text: chunk,
            status: 'approved',
            tag: detectContentTag(chunk),
            timestamp: new Date().toISOString(),
            filename: filename,
          });
        });
      } else {
        chunks.push({
          id: `${filename}_page_${index + 1}`,
          page: index + 1,
          text: page.trim(),
          status: 'approved',
          tag: detectContentTag(page),
          timestamp: new Date().toISOString(),
          filename: filename,
        });
      }
    });
  }

  console.log(`✅ Page-based chunking created ${chunks.length} chunks`);
  return chunks;
}

// Check if content is junk (headers, footers, page numbers)
function isJunkContent(text) {
  const lowerText = text.toLowerCase().trim();

  // Too short
  if (lowerText.length < 50) return true;

  // Just page numbers
  if (/^\d+$/.test(lowerText)) return true;

  // Just headers/footers
  if (/^(page \d+|chapter \d+|section \d+)$/i.test(lowerText)) return true;

  // Mostly punctuation or whitespace
  const alphaNumeric = lowerText.replace(/[^a-z0-9]/g, '');
  if (alphaNumeric.length < lowerText.length * 0.3) return true;

  // Common junk patterns
  const junkPatterns = [
    /^(dit|university|prospectus)$/i,
    /^(table of contents|index)$/i,
    /^(copyright|all rights reserved)$/i,
  ];

  return junkPatterns.some(pattern => pattern.test(lowerText));
}

// Select most relevant chunks when there are too many
function selectMostRelevantChunks(chunks, maxChunks) {
  // Prioritize chunks by relevance score
  const scoredChunks = chunks.map(chunk => ({
    ...chunk,
    relevanceScore: calculateRelevanceScore(chunk)
  }));

  // Sort by relevance score (highest first)
  scoredChunks.sort((a, b) => b.relevanceScore - a.relevanceScore);

  // Take top chunks
  return scoredChunks.slice(0, maxChunks);
}

// Calculate relevance score for a chunk
function calculateRelevanceScore(chunk) {
  let score = 0;
  const text = chunk.text.toLowerCase();

  // Higher score for program-related content
  if (text.includes('bachelor') || text.includes('master') || text.includes('diploma')) score += 10;
  if (text.includes('program') || text.includes('course') || text.includes('degree')) score += 8;

  // Higher score for practical information
  if (text.includes('fee') || text.includes('cost') || text.includes('tuition')) score += 7;
  if (text.includes('admission') || text.includes('requirement') || text.includes('entry')) score += 7;
  if (text.includes('contact') || text.includes('phone') || text.includes('email')) score += 6;

  // Higher score for structured content
  if (text.includes('duration:') || text.includes('requirements:') || text.includes('career:')) score += 5;

  // Bonus for longer, more detailed content
  if (chunk.text.length > 1000) score += 3;
  if (chunk.text.length > 2000) score += 2;

  // Penalty for very short content
  if (chunk.text.length < 200) score -= 5;

  return score;
}

// Enhanced Hugging Face Models Configuration (using VERIFIED working models only)
const HF_MODELS = {
  // Question Answering Models (VERIFIED WORKING)
  qa_primary: 'deepset/roberta-base-squad2',
  qa_conversational: 'microsoft/DialoGPT-medium',
  qa_advanced: 'deepset/roberta-base-squad2', // Use same as primary (known working)

  // Text Classification Models (VERIFIED WORKING)
  intent_classifier: 'facebook/bart-large-mnli',
  quality_scorer: 'facebook/bart-large-mnli', // Use same as intent (known working)
  topic_classifier: 'facebook/bart-large-mnli', // Use same model for consistency

  // Text Generation Models (VERIFIED WORKING)
  summarizer: 'facebook/bart-large-cnn',
  text_generator: 'facebook/bart-large-cnn', // Use summarizer for text generation too

  // Embedding Models (DISABLED - not available via API)
  embeddings: null, // Will use keyword search fallback
  semantic_search: null, // Will use keyword search fallback

  // Specialized Models (SIMPLIFIED)
  ner_extractor: 'facebook/bart-large-mnli', // Use classification model
  similarity_scorer: 'facebook/bart-large-mnli' // Use classification model
};

// Quick response for common questions (no AI needed)
function getQuickResponse(question) {
  const questionLower = question.toLowerCase().trim();

  // Common greetings and simple questions
  const quickResponses = {
    'hello': 'Hello. What would you like to know about the prospectus?',
    'hi': 'Hi. What information do you need?',
    'help': 'I can help with questions about programs, fees, admission requirements, and other prospectus information.',
    'what can you do': 'I can answer questions about programs, fees, admission requirements, and other information from the prospectus.',
    'test': 'Working.',
    'status': 'Online.',
    'ping': 'Online.'
  };

  // Check for exact matches first
  if (quickResponses[questionLower]) {
    return quickResponses[questionLower];
  }

  // Check for partial matches
  for (const [key, response] of Object.entries(quickResponses)) {
    if (questionLower.includes(key)) {
      return response;
    }
  }

  return null; // No quick response available
}

// Enhanced Hugging Face API Functions
async function callHuggingFaceAPI(model, inputs, parameters = {}) {
  const requestId = Date.now();
  const startTime = Date.now();

  try {
    console.log(`🤗 [${requestId}] Calling Hugging Face API: ${model}`);
    console.log(`📊 [${requestId}] Input size: ${JSON.stringify(inputs).length} chars`);

    // Try with API key first, fallback to free inference if 401
    let headers = {
      'Content-Type': 'application/json'
    };

    if (HUGGING_FACE_API_KEY && HUGGING_FACE_API_KEY !== 'hf_YOUR_NEW_TOKEN_HERE') {
      console.log(`🔑 [${requestId}] Using API key: ${HUGGING_FACE_API_KEY.substring(0, 10)}...`);
      headers['Authorization'] = `Bearer ${HUGGING_FACE_API_KEY}`;
    } else {
      console.log(`🆓 [${requestId}] Using free inference (no API key)`);
    }

    // Create timeout promise (20 seconds to leave buffer for Render's 30s limit)
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error(`Hugging Face API timeout after 20 seconds for model: ${model}`));
      }, 20000);
    });

    // Create API request promise
    const apiPromise = axios.post(
      `${HF_API_URL}/${model}`,
      {
        inputs: inputs,
        parameters: parameters
      },
      {
        headers: headers,
        timeout: 20000 // 20 second timeout
      }
    );

    // Race between API call and timeout
    const response = await Promise.race([apiPromise, timeoutPromise]);

    const responseTime = Date.now() - startTime;
    console.log(`✅ [${requestId}] Hugging Face API success: ${response.status} (${responseTime}ms)`);
    console.log(`📊 [${requestId}] Response size: ${JSON.stringify(response.data).length} chars`);
    return response.data;
  } catch (error) {
    console.error('❌ Hugging Face API error details:');
    console.error('- Status:', error.response?.status);
    console.error('- Status Text:', error.response?.statusText);
    console.error('- Response Data:', error.response?.data);
    console.error('- Message:', error.message);

    if (error.response?.status === 401) {
      console.error('🔑 Authentication failed - trying fallback without API key');

      // Try again without API key for free inference
      if (HUGGING_FACE_API_KEY && HUGGING_FACE_API_KEY !== 'hf_YOUR_NEW_TOKEN_HERE') {
        console.log('🆓 Retrying with free inference...');
        try {
          const fallbackResponse = await axios.post(
            `${HF_API_URL}/${model}`,
            {
              inputs: inputs,
              parameters: parameters
            },
            {
              headers: {
                'Content-Type': 'application/json'
              },
              timeout: 30000
            }
          );
          console.log('✅ Fallback successful');
          return fallbackResponse.data;
        } catch (fallbackError) {
          console.error('❌ Fallback also failed:', fallbackError.message);
        }
      }
    }

    throw error;
  }
}

async function summarizeWithHuggingFace(text) {
  try {
    // Use BART model for summarization (free and good quality)
    const model = 'facebook/bart-large-cnn';

    // Truncate text if too long (BART has token limits)
    const maxLength = 1000; // Adjust based on model limits
    const truncatedText = text.length > maxLength ? text.substring(0, maxLength) + '...' : text;

    console.log('🤗 Generating summary with Hugging Face BART model...');

    const result = await callHuggingFaceAPI(model, truncatedText, {
      max_length: 200,
      min_length: 50,
      do_sample: false
    });

    // Handle different response formats
    if (Array.isArray(result) && result.length > 0) {
      return result[0].summary_text || result[0].generated_text || 'Summary generated successfully.';
    } else if (result.summary_text) {
      return result.summary_text;
    } else if (result.generated_text) {
      return result.generated_text;
    } else {
      throw new Error('Unexpected response format from Hugging Face');
    }

  } catch (error) {
    console.error('❌ Hugging Face summarization error:', error.message);
    throw error;
  }
}

async function answerQuestionWithHuggingFace(question, context) {
  try {
    // Use a question-answering model
    const model = 'deepset/roberta-base-squad2';

    console.log('🤗 Answering question with Hugging Face QA model...');

    const result = await callHuggingFaceAPI(model, {
      question: question,
      context: context.substring(0, 2000) // Limit context length
    });

    if (result.answer) {
      return result.answer;
    } else {
      throw new Error('No answer found');
    }

  } catch (error) {
    console.error('❌ Hugging Face QA error:', error.message);
    throw error;
  }
}

// Enhanced Semantic Search using Hugging Face Embeddings
async function findRelevantContentEnhanced(question, contentChunks) {
  try {
    console.log('🔍 Using enhanced semantic search...');

    // Step 1: Get question embedding
    const questionEmbedding = await getTextEmbedding(question);

    if (!questionEmbedding) {
      console.log('⚠️ Embedding failed, falling back to simple search');
      return findRelevantContentSimple(question, contentChunks);
    }

    // Step 2: Calculate semantic similarity for each chunk
    const scoredChunks = [];

    for (const chunk of contentChunks) {
      try {
        // Get or calculate chunk embedding
        let chunkEmbedding = chunk.embedding;
        if (!chunkEmbedding) {
          chunkEmbedding = await getTextEmbedding(chunk.text.substring(0, 500)); // Limit for API
          chunk.embedding = chunkEmbedding; // Cache for future use
        }

        if (chunkEmbedding) {
          const semanticScore = calculateCosineSimilarity(questionEmbedding, chunkEmbedding);
          const keywordScore = calculateKeywordScore(question, chunk.text);
          const combinedScore = (semanticScore * 0.7) + (keywordScore * 0.3);

          if (combinedScore > 0.1) { // Minimum relevance threshold
            scoredChunks.push({
              ...chunk,
              relevance: combinedScore,
              semanticScore: semanticScore,
              keywordScore: keywordScore
            });
          }
        }
      } catch (error) {
        console.log(`⚠️ Error processing chunk ${chunk.id}: ${error.message}`);
        // Fallback to keyword scoring for this chunk
        const keywordScore = calculateKeywordScore(question, chunk.text);
        if (keywordScore > 0.2) {
          scoredChunks.push({
            ...chunk,
            relevance: keywordScore,
            semanticScore: 0,
            keywordScore: keywordScore
          });
        }
      }
    }

    // Step 3: Sort and return top results
    const topChunks = scoredChunks
      .sort((a, b) => b.relevance - a.relevance)
      .slice(0, 5); // Get top 5 for better context

    console.log(`🎯 Found ${topChunks.length} relevant chunks with enhanced search`);

    return topChunks;

  } catch (error) {
    console.log('❌ Enhanced search failed, using simple search:', error.message);
    return findRelevantContentSimple(question, contentChunks);
  }
}

// Get text embedding using Hugging Face (with fallback)
async function getTextEmbedding(text) {
  try {
    // Note: Embedding models may not be available via Hugging Face Inference API
    // This is a placeholder that will gracefully fail and use keyword search instead
    console.log('⚠️ Embedding models not available via HF API, using keyword search fallback');
    return null;

    /*
    // Uncomment this if you have access to embedding models
    const response = await callHuggingFaceAPI(
      HF_MODELS.embeddings,
      text,
      {
        wait_for_model: true,
        use_cache: true
      }
    );

    // Handle different response formats
    if (Array.isArray(response) && response.length > 0) {
      return response[0]; // Some models return array of arrays
    } else if (response && typeof response === 'object') {
      return response.embeddings || response.data || response;
    }

    return null;
    */
  } catch (error) {
    console.log(`⚠️ Embedding generation failed: ${error.message}`);
    return null;
  }
}

// Calculate cosine similarity between two vectors
function calculateCosineSimilarity(vecA, vecB) {
  if (!vecA || !vecB || vecA.length !== vecB.length) {
    return 0;
  }

  try {
    const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
    const magnitudeA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
    const magnitudeB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));

    if (magnitudeA === 0 || magnitudeB === 0) return 0;

    return dotProduct / (magnitudeA * magnitudeB);
  } catch (error) {
    console.log('⚠️ Similarity calculation failed');
    return 0;
  }
}

// Enhanced keyword scoring
function calculateKeywordScore(question, text) {
  const questionLower = question.toLowerCase();
  const textLower = text.toLowerCase();
  const questionWords = questionLower.split(' ').filter(word => word.length > 2);

  let score = 0;

  // Exact phrase match (highest weight)
  if (textLower.includes(questionLower)) {
    score += 10;
  }

  // Individual word matches
  questionWords.forEach(word => {
    const wordCount = (textLower.match(new RegExp(word, 'g')) || []).length;
    score += wordCount * 2;
  });

  // Topic-specific keyword boosts
  const topicBoosts = {
    'program': ['bachelor', 'master', 'diploma', 'degree', 'course', 'study'],
    'fee': ['cost', 'tuition', 'payment', 'scholarship', 'financial', 'tsh'],
    'admission': ['requirement', 'entry', 'application', 'qualify', 'eligible', 'form'],
    'contact': ['phone', 'email', 'address', 'office', 'location', 'reach'],
    'campus': ['location', 'address', 'situated', 'building', 'facility'],
    'duration': ['year', 'years', 'semester', 'month', 'time', 'period']
  };

  Object.entries(topicBoosts).forEach(([topic, keywords]) => {
    if (questionLower.includes(topic)) {
      keywords.forEach(keyword => {
        if (textLower.includes(keyword)) {
          score += 3;
        }
      });
    }
  });

  // Normalize score by text length to avoid bias toward longer texts
  return score / Math.max(text.length / 1000, 1);
}

// Simple content matching (fallback)
function findRelevantContentSimple(question, contentChunks) {
  const questionLower = question.toLowerCase();
  const questionWords = questionLower.split(' ').filter(word => word.length > 2);

  const scoredChunks = contentChunks.map(chunk => {
    const chunkText = chunk.text.toLowerCase();
    let score = 0;

    // Count word matches
    questionWords.forEach(word => {
      const wordCount = (chunkText.match(new RegExp(word, 'g')) || []).length;
      score += wordCount;
    });

    // Boost score for exact phrase matches
    if (chunkText.includes(questionLower)) {
      score += 10;
    }

    // Boost score for topic-specific keywords
    const topicBoosts = {
      'fee': ['fee', 'cost', 'tuition', 'payment', 'price', 'ksh'],
      'admission': ['admission', 'requirement', 'entry', 'kcse', 'grade'],
      'program': ['program', 'course', 'degree', 'bachelor', 'master'],
      'application': ['application', 'apply', 'deadline', 'form'],
      'contact': ['contact', 'phone', 'email', 'address']
    };

    Object.entries(topicBoosts).forEach(([topic, keywords]) => {
      if (questionLower.includes(topic)) {
        keywords.forEach(keyword => {
          if (chunkText.includes(keyword)) {
            score += 5;
          }
        });
      }
    });

    return {
      ...chunk,
      relevance: score
    };
  });

  return scoredChunks
    .filter(chunk => chunk.relevance > 0)
    .sort((a, b) => b.relevance - a.relevance)
    .slice(0, 3);
}

// Enhanced Question Intent Classification
async function classifyQuestionIntent(question) {
  try {
    console.log('🎯 Classifying question intent...');

    const intents = [
      'factual information request',
      'comparison question',
      'procedural instruction',
      'list or enumeration',
      'definition or explanation',
      'cost or fee inquiry',
      'requirement or criteria',
      'contact information',
      'general conversation'
    ];

    const classificationPrompt = `Classify this question into one of these categories: ${intents.join(', ')}. Question: "${question}"`;

    const result = await callHuggingFaceAPI(
      HF_MODELS.intent_classifier,
      classificationPrompt,
      {
        candidate_labels: intents,
        multi_label: false
      }
    );

    const intent = result.labels ? result.labels[0] : 'factual information request';
    const confidence = result.scores ? result.scores[0] : 0.5;

    console.log(`🎯 Intent: ${intent} (confidence: ${confidence.toFixed(2)})`);

    return {
      intent: intent,
      confidence: confidence,
      isHighConfidence: confidence > 0.7
    };

  } catch (error) {
    console.log('⚠️ Intent classification failed, using default');
    return {
      intent: 'factual information request',
      confidence: 0.5,
      isHighConfidence: false
    };
  }
}

// Enhanced Question Type Detection
function detectQuestionType(question) {
  const lowerQuestion = question.toLowerCase();

  const patterns = {
    list: /what.*(?:programs?|courses?|options?|types?|kinds?)|list.*|tell me about all/i,
    comparison: /(?:compare|difference|better|vs|versus|which.*better|how.*different)/i,
    cost: /(?:cost|fee|fees|price|tuition|expensive|cheap|afford)/i,
    requirement: /(?:requirement|requirements|need|needed|qualify|eligible|criteria)/i,
    procedure: /(?:how.*to|process|procedure|steps|apply|application)/i,
    definition: /(?:what.*is|define|meaning|explain|tell me about)/i,
    contact: /(?:contact|phone|email|address|reach|call)/i,
    location: /(?:where|location|address|campus|situated)/i,
    time: /(?:when|time|date|deadline|schedule|duration)/i
  };

  for (const [type, pattern] of Object.entries(patterns)) {
    if (pattern.test(lowerQuestion)) {
      return type;
    }
  }

  return 'general';
}

// Generate answer using Hugging Face with enhanced intelligence
async function generateAnswerWithHuggingFace(question, relevantChunks, history = []) {
  try {
    if (relevantChunks.length === 0) {
      return "Unable to find information about that topic.";
    }

    // Step 1: Classify question intent
    const intentResult = await classifyQuestionIntent(question);
    const questionType = detectQuestionType(question);

    console.log(`🤗 Generating answer with enhanced intelligence...`);
    console.log(`📝 Question type: ${questionType}`);
    console.log(`🎯 Intent: ${intentResult.intent}`);

    const context = relevantChunks
      .map(chunk => chunk.text)
      .join('\n\n');

    // Check if this is a list-type question that needs comprehensive answers
    const questionLower = question.toLowerCase();
    const isListQuestion = questionLower.includes('all') ||
      questionLower.includes('list') ||
      questionLower.includes('what programs') ||
      questionLower.includes('available programs') ||
      questionLower.includes('name the programs') ||
      questionLower.includes('what are the fees') ||
      questionLower.includes('what fees') ||
      questionLower.includes('what are the requirements') ||
      questionLower.includes('what requirements') ||
      (questionLower.includes('what') && questionLower.includes('fee')) ||
      (questionLower.includes('what') && questionLower.includes('program')) ||
      (questionLower.includes('what') && questionLower.includes('requirement'));

    // Step 2: Select optimal model and approach based on question type and intent
    let selectedModel = HF_MODELS.qa_primary;
    let useSpecializedApproach = false;

    // Model selection logic
    if (isListQuestion || intentResult.intent === 'list or enumeration') {
      console.log('📋 Using comprehensive extraction for list question');
      useSpecializedApproach = true;
    } else if (questionType === 'comparison' || intentResult.intent === 'comparison question') {
      console.log('⚖️ Using advanced model for comparison question');
      selectedModel = HF_MODELS.qa_advanced;
    } else if (questionType === 'definition' || intentResult.intent === 'definition or explanation') {
      console.log('📖 Using summarization approach for definition');
      selectedModel = HF_MODELS.summarizer;
      useSpecializedApproach = true;
    } else if (history.length > 0) {
      console.log('💬 Using conversational model for follow-up');
      selectedModel = HF_MODELS.qa_conversational;
    } else if (intentResult.isHighConfidence) {
      console.log('🎯 Using advanced model for high-confidence intent');
      selectedModel = HF_MODELS.qa_advanced;
    }

    // Step 3: Generate answer using selected approach
    let answer = '';

    if (useSpecializedApproach) {
      if (isListQuestion || intentResult.intent === 'list or enumeration') {
        answer = await generateListAnswer(question, relevantChunks);
      } else if (questionType === 'definition' || intentResult.intent === 'definition or explanation') {
        answer = await generateDefinitionAnswer(question, relevantChunks);
      } else {
        answer = extractComprehensiveAnswer(question, relevantChunks);
      }
    } else {
      answer = await generateModelBasedAnswer(question, context, selectedModel, history);
    }

    // Step 4: Validate and enhance answer quality
    const qualityScore = await validateAnswerQuality(question, answer, context);

    if (qualityScore.isGood) {
      const enhancedAnswer = await enhanceAnswerWithContext(answer, relevantChunks, questionType);
      return enhancedAnswer;
    } else {
      console.log('⚠️ Low quality answer detected, trying fallback approach');
      const fallbackAnswer = await generateFallbackAnswer(question, relevantChunks);
      return fallbackAnswer;
    }

  } catch (error) {
    console.error('❌ Hugging Face answer generation error:', error.message);

    // Reconstruct context from relevantChunks for error handling
    const contextForCheck = relevantChunks
      .map(chunk => chunk.text)
      .join('\n\n');

    // Check if question is answerable from the content before falling back to summarization
    const isAnswerable = checkIfQuestionIsAnswerable(question, contextForCheck);

    if (!isAnswerable) {
      // Question is not answerable from the content - give helpful response
      console.log('❌ Question not answerable from content, providing helpful guidance...');
      return "Unable to find information about that topic.";
    }

    // Try fallback answer generation
    try {
      console.log('🔄 Trying fallback answer generation...');
      const fallbackAnswer = await generateFallbackAnswer(question, relevantChunks);
      return fallbackAnswer;
    } catch (fallbackError) {
      console.error('❌ Fallback also failed:', fallbackError.message);

      // Final text-only fallback (no AI required)
      console.log('📄 Using text-only extraction as final fallback...');
      return generateTextOnlyAnswer(question, relevantChunks);
    }
  }
}

// Enhanced List Answer Generation using Multiple Models
async function generateListAnswer(question, relevantChunks) {
  try {
    console.log('📋 Generating comprehensive list answer...');

    const allText = relevantChunks.map(chunk => chunk.text).join('\n\n');
    const questionLower = question.toLowerCase();

    // Use text generation model for structured lists
    const listPrompt = `Based on the following content, provide a comprehensive list to answer: "${question}"\n\nContent: ${allText.substring(0, 2000)}`;

    const generatedList = await callHuggingFaceAPI(
      HF_MODELS.text_generator,
      listPrompt,
      {
        max_length: 500,
        temperature: 0.3,
        do_sample: true
      }
    );

    // Enhance with extracted information
    let enhancedAnswer = '';
    if (generatedList && generatedList.length > 0) {
      enhancedAnswer = generatedList[0].generated_text || generatedList;
    }

    // Add specific extractions based on question type
    if (questionLower.includes('fee') || questionLower.includes('cost')) {
      const feeInfo = extractAllFees(allText);
      enhancedAnswer += '\n\n' + feeInfo;
    } else if (questionLower.includes('program') || questionLower.includes('course')) {
      const programInfo = extractAllPrograms(allText);
      enhancedAnswer += '\n\n' + programInfo;
    } else if (questionLower.includes('requirement')) {
      const reqInfo = extractAllRequirements(allText);
      enhancedAnswer += '\n\n' + reqInfo;
    }

    return `${enhancedAnswer}\n\n💡 **Source**: Compiled from ${relevantChunks.length} section(s) of the prospectus.\n🤗 **Powered by**: Hugging Face T5 + Enhanced extraction`;

  } catch (error) {
    console.log('⚠️ List generation failed, using fallback');
    return extractComprehensiveAnswer(question, relevantChunks);
  }
}

// Enhanced Definition Answer Generation
async function generateDefinitionAnswer(question, relevantChunks) {
  try {
    console.log('📖 Generating definition answer...');

    const context = relevantChunks.map(chunk => chunk.text).join('\n\n');

    // Use summarization model for definitions
    const definitionPrompt = `Provide a clear definition and explanation for: "${question}"\n\nBased on this content: ${context.substring(0, 1500)}`;

    const summary = await callHuggingFaceAPI(
      HF_MODELS.summarizer,
      definitionPrompt,
      {
        max_length: 200,
        min_length: 50,
        do_sample: false
      }
    );

    let answer = '';
    if (summary && summary.length > 0) {
      answer = summary[0].summary_text || summary;
    }

    return `${answer}\n\n💡 **Source**: Summarized from ${relevantChunks.length} section(s) of the prospectus.\n🤗 **Powered by**: Hugging Face BART summarization`;

  } catch (error) {
    console.log('⚠️ Definition generation failed, using fallback');
    return extractKeyInformation(relevantChunks.map(c => c.text).join('\n\n'), question);
  }
}

// Model-based Answer Generation with Conversation Support
async function generateModelBasedAnswer(question, context, selectedModel, history = []) {
  try {
    console.log(`🤖 Using model: ${selectedModel}`);

    // Prepare context with conversation history
    let enhancedContext = context;
    if (history.length > 0) {
      const recentHistory = history.slice(-3); // Last 3 exchanges
      const historyText = recentHistory.map(h => `Q: ${h.question}\nA: ${h.answer}`).join('\n\n');
      enhancedContext = `Previous conversation:\n${historyText}\n\nCurrent context:\n${context}`;
    }

    let answer = '';

    if (selectedModel === HF_MODELS.qa_conversational) {
      // Use conversational model
      const conversationInput = `${enhancedContext}\n\nHuman: ${question}\nAssistant:`;
      const response = await callHuggingFaceAPI(
        selectedModel,
        conversationInput,
        {
          max_length: 300,
          temperature: 0.7,
          pad_token_id: 50256
        }
      );
      answer = response.generated_text || response;
    } else {
      // Use QA model
      const qaResponse = await callHuggingFaceAPI(
        selectedModel,
        {
          question: question,
          context: enhancedContext.substring(0, 2000)
        }
      );
      answer = qaResponse.answer || qaResponse;
    }

    return answer;

  } catch (error) {
    console.log(`⚠️ Model ${selectedModel} failed, using fallback`);
    throw error;
  }
}

// Extract comprehensive answers for list-type questions (fallback)
function extractComprehensiveAnswer(question, relevantChunks) {
  const questionLower = question.toLowerCase();
  const allText = relevantChunks.map(chunk => chunk.text).join('\n\n');

  // More specific detection - check for fee questions first
  if ((questionLower.includes('fee') || questionLower.includes('cost') || questionLower.includes('tuition')) &&
    !questionLower.includes('program')) {
    return extractAllFees(allText);
  } else if (questionLower.includes('program') || questionLower.includes('course') || questionLower.includes('degree')) {
    return extractAllPrograms(allText);
  } else if (questionLower.includes('requirement') || questionLower.includes('admission')) {
    return extractAllRequirements(allText);
  } else if (questionLower.includes('contact') || questionLower.includes('phone') || questionLower.includes('email')) {
    return extractContactInfo(allText);
  } else {
    // General comprehensive extraction
    return extractKeyInformation(allText, question);
  }
}

function extractAllPrograms(text) {
  const programs = new Set(); // Use Set to avoid duplicates

  // Enhanced program extraction patterns
  const engineeringPrograms = [
    'CIVIL ENGINEERING',
    'COMPUTER ENGINEERING',
    'ELECTRICAL ENGINEERING',
    'ELECTRONICS AND TELECOMMUNICATIONS ENGINEERING',
    'ELECTRONICS AND TELECOMMUNICATION ENGINEERING',
    'MECHANICAL ENGINEERING',
    'BIOMEDICAL ENGINEERING',
    'BIOMEDICAL EQUIPMENT ENGINEERING',
    'SUSTAINABLE ENERGY ENGINEERING',
    'MINING ENGINEERING',
    'OIL AND GAS ENGINEERING'
  ];

  const technologyPrograms = [
    'INFORMATION TECHNOLOGY',
    'COMPUTER STUDIES',
    'MULTIMEDIA AND FILM TECHNOLOGY',
    'COMMUNICATION SYSTEM TECHNOLOGY',
    'RENEWABLE ENERGY TECHNOLOGY',
    'BIOTECHNOLOGY',
    'FOOD SCIENCE AND TECHNOLOGY',
    'LEATHER PRODUCTS TECHNOLOGY',
    'LEATHER PROCESSING TECHNOLOGY',
    'SCIENCE AND LABORATORY TECHNOLOGY',
    'INDUSTRIAL AUTOMATION',
    'TEXTILE TECHNOLOGY',
    'POST-HARVEST TECHNOLOGY',
    'FASHION AND DESIGN TECHNOLOGY',
    'BIOPROCESS TECHNOLOGY'
  ];

  const sciencePrograms = [
    'COMPUTATIONAL SCIENCE AND ENGINEERING',
    'CYBERSECURITY AND DIGITAL FORENSICS',
    'TELECOMMUNICATIONS SYSTEMS AND NETWORKS',
    'MAINTENANCE MANAGEMENT',
    'COMPUTING AND COMMUNICATIONS TECHNOLOGY'
  ];

  const allPrograms = [...engineeringPrograms, ...technologyPrograms, ...sciencePrograms];

  // Search for programs in the text
  const upperText = text.toUpperCase();

  for (const program of allPrograms) {
    if (upperText.includes(program)) {
      // Determine the level (Bachelor, Diploma, Certificate, Master)
      const levels = [];

      if (upperText.includes(`BACHELOR OF ${program}`) || upperText.includes(`BACHELOR IN ${program}`)) {
        levels.push('Bachelor');
      }
      if (upperText.includes(`MASTER OF ${program}`) || upperText.includes(`MASTER IN ${program}`)) {
        levels.push('Master');
      }
      if (upperText.includes(`DIPLOMA IN ${program}`) || upperText.includes(`ORDINARY DIPLOMA IN ${program}`)) {
        levels.push('Diploma');
      }
      if (upperText.includes(`CERTIFICATE IN ${program}`) || upperText.includes(`TECHNICIAN CERTIFICATE IN ${program}`)) {
        levels.push('Certificate');
      }

      // Add programs with their levels
      if (levels.length > 0) {
        for (const level of levels) {
          programs.add(`${level} in ${program.toLowerCase().replace(/\b\w/g, l => l.toUpperCase())}`);
        }
      } else {
        // Add without level if found but level not specified
        programs.add(program.toLowerCase().replace(/\b\w/g, l => l.toUpperCase()));
      }
    }
  }

  // Also look for specific program mentions in department names
  const departmentMatches = text.match(/Department of ([^(\n]+)/gi);
  if (departmentMatches) {
    for (const match of departmentMatches) {
      const dept = match.replace(/Department of /i, '').trim();
      if (dept.length > 5 && dept.length < 50) {
        programs.add(`Programs in ${dept}`);
      }
    }
  }

  // Convert Set to Array and sort
  const programList = Array.from(programs).sort();

  if (programList.length > 0) {
    const intro = getTranslation('programsIntro');
    const campusInfo = getTranslation('campusInfo');

    let translatedPrograms = programList;
    if (currentLanguage === 'swahili') {
      translatedPrograms = programList.map(prog => translateToSwahili(prog));
    }

    return `${intro}\n\n${translatedPrograms.map((prog, index) => `${index + 1}. ${prog}`).join('\n')}\n\n${campusInfo}`;
  } else {
    if (currentLanguage === 'swahili') {
      return "Nimepata maelezo ya mipango katika prospektasi. DIT inatoa mipango mbalimbali ya uhandisi na teknolojia katika viwango mbalimbali ikiwa ni pamoja na vyeti, diploma, shahada za kwanza na za uzamili.";
    } else {
      return "I found program information in the prospectus. DIT offers various engineering and technology programs across multiple levels including certificates, diplomas, bachelor's and master's degrees.";
    }
  }
}

function extractAllFees(text) {
  const fees = new Set(); // Use Set to avoid duplicates
  const lines = text.split('\n');

  // Enhanced fee patterns
  const feePatterns = [
    /TSh\s*[\d,]+/gi,
    /KSh\s*[\d,]+/gi,
    /USD\s*[\d,]+/gi,
    /fee[s]?\s*[:=]\s*TSh\s*[\d,]+/gi,
    /tuition\s*[:=]\s*TSh\s*[\d,]+/gi,
    /cost\s*[:=]\s*TSh\s*[\d,]+/gi,
    /per\s+year\s*[:=]\s*TSh\s*[\d,]+/gi,
    /per\s+semester\s*[:=]\s*TSh\s*[\d,]+/gi
  ];

  // Look for fee-related lines
  for (const line of lines) {
    const lowerLine = line.toLowerCase();

    // Check if line contains fee-related keywords and amounts
    if ((lowerLine.includes('tsh') || lowerLine.includes('fee') || lowerLine.includes('cost') ||
      lowerLine.includes('tuition') || lowerLine.includes('payment')) &&
      (lowerLine.includes('year') || lowerLine.includes('semester') || lowerLine.includes('month'))) {

      const cleanLine = line.replace(/^[-\s]*/, '').trim();
      if (cleanLine.length > 15 && cleanLine.length < 200) {
        fees.add(cleanLine);
      }
    }

    // Extract specific fee patterns
    for (const pattern of feePatterns) {
      const matches = line.match(pattern);
      if (matches) {
        matches.forEach(match => {
          if (match.trim().length > 5) {
            fees.add(match.trim());
          }
        });
      }
    }
  }

  // Look for program-specific fees
  const programFeePatterns = [
    /(?:bachelor|diploma|certificate|master).*?tsh\s*[\d,]+/gi,
    /(?:engineering|technology|science).*?tsh\s*[\d,]+/gi,
    /(?:computer|civil|electrical|mechanical).*?tsh\s*[\d,]+/gi
  ];

  for (const pattern of programFeePatterns) {
    const matches = text.match(pattern);
    if (matches) {
      matches.forEach(match => {
        const cleanMatch = match.replace(/\s+/g, ' ').trim();
        if (cleanMatch.length > 10 && cleanMatch.length < 150) {
          fees.add(cleanMatch);
        }
      });
    }
  }

  // Convert Set to Array and sort
  const feeList = Array.from(fees).sort();

  if (feeList.length > 0) {
    const intro = getTranslation('feesIntro');
    const note = getTranslation('feesNote');

    let translatedFees = feeList;
    if (currentLanguage === 'swahili') {
      translatedFees = feeList.map(fee => translateToSwahili(fee));
    }

    return `${intro}\n\n${translatedFees.map((fee, index) => `${index + 1}. ${fee}`).join('\n')}\n\n${note}`;
  } else {
    return getTranslation('feesNotFound');
  }
}

function extractAllRequirements(text) {
  const requirements = [];
  const lines = text.split('\n');
  let inRequirementsSection = false;

  for (const line of lines) {
    if (line.toUpperCase().includes('REQUIREMENT') || line.toUpperCase().includes('ENTRY')) {
      inRequirementsSection = true;
      continue;
    }

    if (inRequirementsSection && line.trim().length > 0) {
      if (line.includes('Form IV') || line.includes('Certificate') || line.includes('Grade') || line.includes('Division')) {
        requirements.push(line.replace(/^-\s*/, '').trim());
      }
    }
  }

  if (requirements.length > 0) {
    return `Admission requirements at DIT University:\n\n${requirements.map((req, index) => `${index + 1}. ${req}`).join('\n')}`;
  } else {
    return "I found admission requirements in the prospectus. Generally, you need a Form IV Certificate with appropriate grades for your chosen program.";
  }
}

function extractContactInfo(text) {
  const contactInfo = [];
  const lines = text.split('\n');

  for (const line of lines) {
    if (line.includes('@') || line.includes('+255') || line.includes('Phone') || line.includes('Email') || line.includes('Address')) {
      contactInfo.push(line.replace(/^-\s*/, '').trim());
    }
  }

  if (contactInfo.length > 0) {
    return `Contact information for DIT University:\n\n${contactInfo.join('\n')}`;
  } else {
    return "Contact information is available in the prospectus. You can reach DIT University through their official channels.";
  }
}

function extractKeyInformation(text, question) {
  // Extract the most relevant sentences based on the question
  const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 20);
  const questionWords = question.toLowerCase().split(' ').filter(w => w.length > 3);

  const relevantSentences = sentences.filter(sentence => {
    const sentenceLower = sentence.toLowerCase();
    return questionWords.some(word => sentenceLower.includes(word));
  }).slice(0, 5); // Top 5 most relevant sentences

  if (relevantSentences.length > 0) {
    return relevantSentences.join('. ') + '.';
  } else {
    return "I found relevant information in the prospectus, but couldn't extract specific details for your question.";
  }
}

// Check if a question is answerable from the document content
function checkIfQuestionIsAnswerable(question, context) {
  const lowerQuestion = question.toLowerCase();
  const lowerContext = context.toLowerCase();

  // Questions that are clearly answerable from academic prospectus
  const answerableKeywords = [
    'program', 'course', 'degree', 'diploma', 'certificate', 'bachelor', 'master',
    'fee', 'cost', 'tuition', 'price', 'payment',
    'admission', 'requirement', 'entry', 'qualification',
    'campus', 'location', 'address', 'contact',
    'duration', 'semester', 'year',
    'department', 'faculty', 'school',
    'dit', 'university', 'institute', 'technology'
  ];

  // Questions that are clearly NOT answerable from academic prospectus
  const unanswerableKeywords = [
    'weather', 'climate', 'temperature',
    'restaurant', 'food', 'hotel', 'accommodation',
    'transport', 'bus', 'flight', 'travel',
    'politics', 'government', 'president',
    'sports', 'football', 'soccer',
    'entertainment', 'movie', 'music',
    'shopping', 'market', 'store'
  ];

  // Check for unanswerable keywords first
  for (const keyword of unanswerableKeywords) {
    if (lowerQuestion.includes(keyword)) {
      return false;
    }
  }

  // Check for answerable keywords
  for (const keyword of answerableKeywords) {
    if (lowerQuestion.includes(keyword)) {
      return true;
    }
  }

  // Check if question words appear in context
  const questionWords = lowerQuestion.split(' ').filter(word => word.length > 3);
  let contextMatches = 0;

  for (const word of questionWords) {
    if (lowerContext.includes(word)) {
      contextMatches++;
    }
  }

  // If more than 30% of question words appear in context, it's likely answerable
  return (contextMatches / questionWords.length) > 0.3;
}

// Answer Quality Validation using Hugging Face
async function validateAnswerQuality(question, answer, context) {
  try {
    console.log('🔍 Validating answer quality...');

    // Check basic quality metrics
    const basicQuality = {
      hasContent: answer && answer.trim().length > 10,
      isReasonableLength: answer.length >= 20 && answer.length <= 2000,
      notGeneric: !answer.toLowerCase().includes('sorry, i don\'t have information'),
      notError: !answer.toLowerCase().includes('error') && !answer.toLowerCase().includes('failed')
    };

    // Use classification model to check relevance
    let relevanceScore = 0.5;
    try {
      const relevancePrompt = `Question: "${question}"\nAnswer: "${answer}"\nIs this answer relevant and helpful for the question?`;

      const relevanceResult = await callHuggingFaceAPI(
        HF_MODELS.quality_scorer,
        relevancePrompt,
        {
          candidate_labels: ['relevant and helpful', 'partially relevant', 'not relevant'],
          multi_label: false
        }
      );

      if (relevanceResult.labels && relevanceResult.scores) {
        relevanceScore = relevanceResult.labels[0] === 'relevant and helpful' ? relevanceResult.scores[0] : 0.3;
      }
    } catch (error) {
      console.log('⚠️ Relevance scoring failed, using default');
    }

    // Calculate overall quality score
    const qualityFactors = Object.values(basicQuality);
    const basicScore = qualityFactors.filter(Boolean).length / qualityFactors.length;
    const overallScore = (basicScore * 0.6) + (relevanceScore * 0.4);

    console.log(`📊 Quality score: ${overallScore.toFixed(2)} (basic: ${basicScore.toFixed(2)}, relevance: ${relevanceScore.toFixed(2)})`);

    return {
      score: overallScore,
      isGood: overallScore > 0.6,
      relevanceScore: relevanceScore,
      basicQuality: basicQuality,
      details: {
        hasContent: basicQuality.hasContent,
        appropriateLength: basicQuality.isReasonableLength,
        notGeneric: basicQuality.notGeneric,
        noErrors: basicQuality.notError,
        relevant: relevanceScore > 0.5
      }
    };

  } catch (error) {
    console.log('⚠️ Quality validation failed, assuming good quality');
    return {
      score: 0.7,
      isGood: true,
      relevanceScore: 0.7,
      details: { assumed: true }
    };
  }
}

// Enhance Answer with Context and Metadata
async function enhanceAnswerWithContext(answer, relevantChunks, questionType) {
  try {
    console.log('✨ Enhancing answer with context...');
    return answer; // Just return the clean answer without technical details
  } catch (error) {
    console.log('⚠️ Answer enhancement failed, returning original');
    return answer;
  }
}

// Text-only answer generation (no AI required)
function generateTextOnlyAnswer(question, relevantChunks) {
  console.log('📄 Generating text-only answer (no AI models needed)...');

  if (relevantChunks.length === 0) {
    return "Unable to find information about that topic in the prospectus.";
  }

  // Extract and format relevant text
  const extractedContent = relevantChunks
    .slice(0, 2) // Limit to top 2 most relevant chunks
    .map((chunk, index) => {
      const preview = chunk.text.substring(0, 400);
      return preview + (chunk.text.length > 400 ? '...' : '');
    })
    .join('\n\n');

  return extractedContent;
}

// Enhanced Fallback Answer Generation
async function generateFallbackAnswer(question, relevantChunks) {
  try {
    console.log('🔄 Generating enhanced fallback answer...');

    if (relevantChunks.length === 0) {
      return "I couldn't find relevant information about that topic in the uploaded prospectus. Could you try asking about programs, fees, admission requirements, or other topics covered in the document?";
    }

    // Use text generation for fallback
    const context = relevantChunks
      .map(chunk => chunk.text)
      .join('\n\n')
      .substring(0, 1500);

    const fallbackPrompt = `Answer this question based on the provided content: "${question}"\n\nContent: ${context}`;

    try {
      const fallbackResponse = await callHuggingFaceAPI(
        HF_MODELS.text_generator,
        fallbackPrompt,
        {
          max_length: 200,
          temperature: 0.5
        }
      );

      if (fallbackResponse && fallbackResponse.length > 0) {
        const generatedAnswer = fallbackResponse[0].generated_text || fallbackResponse;
        return `${generatedAnswer}\n\n💡 **Source**: Generated from ${relevantChunks.length} section(s) using fallback AI model.`;
      }
    } catch (error) {
      console.log(`⚠️ AI fallback failed (${error.response?.status || 'unknown error'}), using text extraction`);
      if (error.response?.status === 404) {
        console.log('🔧 Model not found - this is expected, using text extraction instead');
      }
    }

    // Final fallback to text extraction
    const extractedContext = relevantChunks
      .slice(0, 2)
      .map(chunk => chunk.text.substring(0, 300))
      .join('\n\n');

    return extractedContext;

  } catch (error) {
    console.log('❌ All fallback methods failed');
    return "Unable to process your question at this time.";
  }
}

// Generate comprehensive PDF summary
async function generatePDFSummary(summaryType = 'overview', maxLength = 500, sections = 'all') {
  try {
    console.log(`📄 Generating ${summaryType} summary (max ${maxLength} chars)`);

    if (processedContent.length === 0) {
      throw new Error('No PDF content available for summarization');
    }

    // Prepare content based on sections requested
    let contentToSummarize = '';

    if (sections === 'all') {
      // Use all content, but prioritize important sections
      const prioritySections = processedContent.filter(chunk =>
        chunk.tag && ['Programs', 'Fees', 'Admission', 'Introduction'].includes(chunk.tag)
      );

      const otherSections = processedContent.filter(chunk =>
        !chunk.tag || !['Programs', 'Fees', 'Admission', 'Introduction'].includes(chunk.tag)
      );

      const priorityContent = prioritySections.map(chunk => chunk.text).join('\n\n');
      const otherContent = otherSections.map(chunk => chunk.text).join('\n\n');

      contentToSummarize = priorityContent + '\n\n' + otherContent;
    } else if (Array.isArray(sections)) {
      // Use specific sections
      const selectedChunks = processedContent.filter(chunk =>
        sections.includes(chunk.tag) || sections.includes(chunk.page?.toString())
      );
      contentToSummarize = selectedChunks.map(chunk => chunk.text).join('\n\n');
    } else {
      contentToSummarize = processedContent.map(chunk => chunk.text).join('\n\n');
    }

    // Limit content length for API (max 2000 chars for summarization)
    if (contentToSummarize.length > 2000) {
      contentToSummarize = contentToSummarize.substring(0, 2000);
    }

    // Generate summary based on type
    let summary = '';

    if (summaryType === 'overview') {
      summary = await generateOverviewSummary(contentToSummarize, maxLength);
    } else if (summaryType === 'programs') {
      summary = await generateProgramsSummary(contentToSummarize, maxLength);
    } else if (summaryType === 'fees') {
      summary = await generateFeesSummary(contentToSummarize, maxLength);
    } else if (summaryType === 'admission') {
      summary = await generateAdmissionSummary(contentToSummarize, maxLength);
    } else {
      summary = await generateOverviewSummary(contentToSummarize, maxLength);
    }

    return summary;

  } catch (error) {
    console.error('❌ PDF summarization failed:', error);
    throw error;
  }
}

// Generate overview summary
async function generateOverviewSummary(content, maxLength) {
  try {
    const prompt = `Provide a comprehensive overview summary of this educational institution document:\n\n${content}`;

    const response = await callHuggingFaceAPI(
      HF_MODELS.summarizer,
      prompt,
      {
        max_length: Math.min(maxLength, 500),
        min_length: Math.min(100, maxLength / 2),
        do_sample: false
      }
    );

    if (response && response.length > 0) {
      const summary = response[0].summary_text || response;
      return `📋 **PDF Overview Summary**\n\n${summary}\n\n📊 **Document Stats**: ${processedContent.length} sections processed\n🤗 **Generated by**: Hugging Face BART summarization model`;
    }

    throw new Error('No summary generated');
  } catch (error) {
    console.log('⚠️ AI summarization failed, using extraction method');
    return generateExtractiveSummary(content, maxLength, 'overview');
  }
}

// Generate programs-focused summary
async function generateProgramsSummary(content, maxLength) {
  try {
    const prompt = `Summarize the academic programs and courses offered by this institution:\n\n${content}`;

    const response = await callHuggingFaceAPI(
      HF_MODELS.summarizer,
      prompt,
      {
        max_length: Math.min(maxLength, 400),
        min_length: Math.min(80, maxLength / 2),
        do_sample: false
      }
    );

    if (response && response.length > 0) {
      const summary = response[0].summary_text || response;
      return `🎓 **Programs Summary**\n\n${summary}\n\n📚 **Focus**: Academic programs and courses\n🤗 **Generated by**: Hugging Face BART model`;
    }

    throw new Error('No programs summary generated');
  } catch (error) {
    console.log('⚠️ Programs summarization failed, using extraction');
    return generateExtractiveSummary(content, maxLength, 'programs');
  }
}

// Generate fees-focused summary
async function generateFeesSummary(content, maxLength) {
  try {
    const prompt = `Summarize the fees, costs, and financial information from this document:\n\n${content}`;

    const response = await callHuggingFaceAPI(
      HF_MODELS.summarizer,
      prompt,
      {
        max_length: Math.min(maxLength, 300),
        min_length: Math.min(60, maxLength / 2),
        do_sample: false
      }
    );

    if (response && response.length > 0) {
      const summary = response[0].summary_text || response;
      return `💰 **Fees Summary**\n\n${summary}\n\n💳 **Focus**: Costs and financial information\n🤗 **Generated by**: Hugging Face BART model`;
    }

    throw new Error('No fees summary generated');
  } catch (error) {
    console.log('⚠️ Fees summarization failed, using extraction');
    return generateExtractiveSummary(content, maxLength, 'fees');
  }
}

// Generate admission-focused summary
async function generateAdmissionSummary(content, maxLength) {
  try {
    const prompt = `Summarize the admission requirements and application process:\n\n${content}`;

    const response = await callHuggingFaceAPI(
      HF_MODELS.summarizer,
      prompt,
      {
        max_length: Math.min(maxLength, 350),
        min_length: Math.min(70, maxLength / 2),
        do_sample: false
      }
    );

    if (response && response.length > 0) {
      const summary = response[0].summary_text || response;
      return `📝 **Admission Summary**\n\n${summary}\n\n🎯 **Focus**: Requirements and application process\n🤗 **Generated by**: Hugging Face BART model`;
    }

    throw new Error('No admission summary generated');
  } catch (error) {
    console.log('⚠️ Admission summarization failed, using extraction');
    return generateExtractiveSummary(content, maxLength, 'admission');
  }
}

// Fallback extractive summary
function generateExtractiveSummary(content, maxLength, type) {
  const sentences = content.split(/[.!?]+/).filter(s => s.trim().length > 20);

  // Score sentences based on type
  const scoredSentences = sentences.map(sentence => {
    let score = 0;
    const lowerSentence = sentence.toLowerCase();

    // General importance keywords
    const importantWords = ['university', 'institute', 'program', 'course', 'degree', 'diploma'];
    importantWords.forEach(word => {
      if (lowerSentence.includes(word)) score += 2;
    });

    // Type-specific keywords
    if (type === 'programs') {
      const programWords = ['bachelor', 'master', 'diploma', 'certificate', 'engineering', 'technology'];
      programWords.forEach(word => {
        if (lowerSentence.includes(word)) score += 3;
      });
    } else if (type === 'fees') {
      const feeWords = ['fee', 'cost', 'tuition', 'payment', 'scholarship', 'tsh'];
      feeWords.forEach(word => {
        if (lowerSentence.includes(word)) score += 3;
      });
    } else if (type === 'admission') {
      const admissionWords = ['admission', 'requirement', 'application', 'qualify', 'form'];
      admissionWords.forEach(word => {
        if (lowerSentence.includes(word)) score += 3;
      });
    }

    return { sentence: sentence.trim(), score };
  });

  // Select top sentences
  const topSentences = scoredSentences
    .sort((a, b) => b.score - a.score)
    .slice(0, 5)
    .map(item => item.sentence);

  let summary = topSentences.join('. ');

  // Trim to max length
  if (summary.length > maxLength) {
    summary = summary.substring(0, maxLength - 3) + '...';
  }

  return `📄 **${type.charAt(0).toUpperCase() + type.slice(1)} Summary** (Extracted)\n\n${summary}\n\n💡 **Method**: Key sentence extraction\n📊 **Source**: ${processedContent.length} document sections`;
}

// OpenAI Helper Functions
async function findRelevantContent(question, contentChunks) {
  try {
    // Create embeddings for the question
    const questionEmbedding = await openai.embeddings.create({
      model: "text-embedding-ada-002",
      input: question,
    });

    // Calculate similarity scores for each chunk
    const scoredChunks = [];

    for (const chunk of contentChunks) {
      // Create embedding for chunk if not exists
      if (!chunk.embedding) {
        const chunkEmbedding = await openai.embeddings.create({
          model: "text-embedding-ada-002",
          input: chunk.text,
        });
        chunk.embedding = chunkEmbedding.data[0].embedding;
      }

      // Calculate cosine similarity
      const similarity = cosineSimilarity(
        questionEmbedding.data[0].embedding,
        chunk.embedding
      );

      if (similarity > 0.7) { // Threshold for relevance
        scoredChunks.push({
          ...chunk,
          relevance: similarity
        });
      }
    }

    // Sort by relevance and return top 3
    return scoredChunks
      .sort((a, b) => b.relevance - a.relevance)
      .slice(0, 3);

  } catch (error) {
    console.error('❌ Error finding relevant content:', error);
    // Fallback to keyword search
    return keywordSearch(question, contentChunks);
  }
}

// Cosine similarity calculation
function cosineSimilarity(vecA, vecB) {
  const dotProduct = vecA.reduce((sum, a, i) => sum + a * vecB[i], 0);
  const magnitudeA = Math.sqrt(vecA.reduce((sum, a) => sum + a * a, 0));
  const magnitudeB = Math.sqrt(vecB.reduce((sum, b) => sum + b * b, 0));
  return dotProduct / (magnitudeA * magnitudeB);
}

// Fallback keyword search
function keywordSearch(question, contentChunks) {
  const questionWords = question.toLowerCase().split(' ');
  const scoredChunks = [];

  contentChunks.forEach(chunk => {
    let score = 0;
    const chunkText = chunk.text.toLowerCase();

    questionWords.forEach(word => {
      if (word.length > 3) {
        const matches = (chunkText.match(new RegExp(word, 'g')) || []).length;
        score += matches;
      }
    });

    if (score > 0) {
      scoredChunks.push({ ...chunk, relevance: score / 10 });
    }
  });

  return scoredChunks
    .sort((a, b) => b.relevance - a.relevance)
    .slice(0, 3);
}

// Generate conversational answer using OpenAI
async function generateConversationalAnswer(question, relevantChunks, history = []) {
  try {
    // Prepare context from relevant chunks
    const context = relevantChunks
      .map(chunk => `Page ${chunk.page}: ${chunk.text}`)
      .join('\n\n');

    // Build conversation history
    let conversationHistory = '';
    if (history && history.length > 0) {
      const recentHistory = history.slice(-3); // Last 3 exchanges
      conversationHistory = recentHistory
        .map(h => `Human: ${h.question}\nAssistant: ${h.answer}`)
        .join('\n\n') + '\n\n';
    }

    // Create the prompt
    const prompt = `You are a helpful assistant for a university admissions office. You help prospective students understand information from the university prospectus.

${conversationHistory}Based on the following prospectus content, please answer the student's question in a conversational, helpful manner:

PROSPECTUS CONTENT:
${context}

STUDENT QUESTION: ${question}

Please provide a clear, conversational answer based ONLY on the information provided above. If the information isn't sufficient to fully answer the question, acknowledge this and suggest they contact the admissions office for more details.`;

    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are a helpful university admissions assistant. Provide clear, conversational answers based on prospectus information."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: parseInt(process.env.OPENAI_MAX_TOKENS) || 500,
      temperature: parseFloat(process.env.OPENAI_TEMPERATURE) || 0.3,
    });

    return completion.choices[0]?.message?.content?.trim() ||
      "Unable to generate a response at this time.";

  } catch (error) {
    console.error('❌ Error generating conversational answer:', error);

    // Fallback to basic answer
    const context = relevantChunks
      .map(chunk => chunk.text.substring(0, 300))
      .join('\n\n');

    return context;
  }
}

// Enhanced health check endpoint for production
app.get('/', (req, res) => {
  const healthStatus = {
    status: 'healthy',
    service: 'VIAS Enhanced Q&A Server',
    version: '2.0.0',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    uptime: Math.floor(process.uptime()),
    processedChunks: processedContent.length,
    currentLanguage: currentLanguage,
    features: {
      huggingFaceAI: !!process.env.HUGGING_FACE_API_KEY,
      multiModelSupport: true,
      semanticSearch: true,
      conversationContext: true,
      qualityValidation: true
    },
    endpoints: {
      health: '/',
      answerQuestion: '/api/answer-question',
      detailedHealth: '/api/health'
    }
  };

  res.json(healthStatus);
});

// Detailed health check endpoint
app.get('/api/health', (req, res) => {
  const memoryUsage = process.memoryUsage();
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'VIAS Q&A Server',
    version: '2.0.0',
    uptime: Math.floor(process.uptime()),
    memory: {
      used: Math.round(memoryUsage.heapUsed / 1024 / 1024) + 'MB',
      total: Math.round(memoryUsage.heapTotal / 1024 / 1024) + 'MB',
      external: Math.round(memoryUsage.external / 1024 / 1024) + 'MB'
    },
    checks: {
      server: 'healthy',
      memory: memoryUsage.heapUsed < 400 * 1024 * 1024 ? 'healthy' : 'warning',
      huggingFace: process.env.HUGGING_FACE_API_KEY ? 'configured' : 'missing',
      contentLoaded: processedContent.length > 0 ? 'ready' : 'empty'
    }
  };

  const isHealthy = health.checks.server === 'healthy' &&
    health.checks.memory !== 'critical';

  res.status(isHealthy ? 200 : 503).json(health);
});

// PDF Summarization endpoint
app.post('/api/summarize-pdf', async (req, res) => {
  try {
    console.log('📄 PDF summarization request received');

    const {
      summaryType = 'overview',
      maxLength = 500,
      sections = 'all'
    } = req.body;

    if (processedContent.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'No PDF content available. Please upload a PDF first.',
        userMessage: 'Please upload a PDF document before requesting a summary.'
      });
    }

    // Generate comprehensive summary
    const summary = await generatePDFSummary(summaryType, maxLength, sections);

    res.json({
      success: true,
      summary: summary,
      summaryType: summaryType,
      contentSections: processedContent.length,
      timestamp: new Date().toISOString(),
      metadata: {
        originalLength: processedContent.reduce((total, chunk) => total + chunk.text.length, 0),
        summaryLength: summary.length,
        compressionRatio: Math.round((summary.length / processedContent.reduce((total, chunk) => total + chunk.text.length, 0)) * 100) + '%'
      }
    });

  } catch (error) {
    console.error('❌ PDF summarization error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      userMessage: 'Failed to generate PDF summary. Please try again.'
    });
  }
});

// Get current language
app.get('/api/language', (req, res) => {
  res.json({
    success: true,
    currentLanguage: currentLanguage,
    availableLanguages: ['english', 'swahili'],
    commands: {
      english: [
        'Change language to Swahili',
        'Switch to Swahili',
        'Use Swahili'
      ],
      swahili: [
        'Badilisha lugha kuwa Kiingereza',
        'Change language to English',
        'Tumia Kiingereza'
      ]
    }
  });
});

// Set language endpoint
app.post('/api/language', (req, res) => {
  const { language } = req.body;

  if (!language || !['english', 'swahili'].includes(language.toLowerCase())) {
    return res.status(400).json({
      success: false,
      error: 'Invalid language',
      message: 'Language must be either "english" or "swahili"'
    });
  }

  const oldLanguage = currentLanguage;
  currentLanguage = language.toLowerCase();

  console.log(`🌍 Language changed from ${oldLanguage} to ${currentLanguage} via API`);

  res.json({
    success: true,
    message: getTranslation('languageChanged'),
    oldLanguage: oldLanguage,
    newLanguage: currentLanguage
  });
});

// Log command usage for tracking
app.post('/api/log-command', (req, res) => {
  const { command, timestamp } = req.body;
  console.log(`📊 Command logged: ${command} at ${timestamp}`);
  res.json({ success: true, message: 'Command logged' });
});

// Process PDF - Handle both multipart uploads and JSON with base64
app.post('/api/process-pdf', upload.single('pdf'), async (req, res) => {
  try {
    let dataBuffer;
    let filename;

    // Check if it's a multipart upload (traditional form upload)
    if (req.file) {
      console.log(`📄 Processing PDF (multipart): ${req.file.originalname}`);
      dataBuffer = fs.readFileSync(req.file.path);
      filename = req.file.originalname;
    }
    // Check if it's JSON with base64 data (Flutter web)
    else if (req.body && req.body.pdfData) {
      console.log(`📄 Processing PDF (base64): ${req.body.filename || 'unknown.pdf'}`);
      try {
        dataBuffer = Buffer.from(req.body.pdfData, 'base64');
        filename = req.body.filename || 'uploaded.pdf';
      } catch (e) {
        return res.status(400).json({ error: 'Invalid base64 PDF data' });
      }
    }
    else {
      return res.status(400).json({
        error: 'No PDF file uploaded. Send either multipart form data or JSON with base64 pdfData.'
      });
    }

    console.log(`📊 PDF size: ${dataBuffer.length} bytes`);

    // Parse PDF with enhanced extraction for large documents
    const pdfData = await pdfParse(dataBuffer, {
      // Enhanced options for better text extraction
      normalizeWhitespace: false,
      disableCombineTextItems: false
    });

    let text = pdfData.text;
    const totalPages = pdfData.numpages;

    console.log(`📝 Raw extracted text length: ${text.length} characters`);
    console.log(`📄 PDF reports ${totalPages} pages`);

    if (text.length < 1000) {
      console.log('⚠️ Very little text extracted, PDF might be image-based or encrypted');
      return res.status(400).json({
        success: false,
        error: 'PDF text extraction failed',
        message: 'The PDF appears to contain mostly images or is encrypted. Please ensure the PDF contains extractable text.',
        totalPages: totalPages
      });
    }

    // Clean and normalize the text
    text = cleanExtractedText(text);

    // For large documents (>100 pages), use intelligent chunking
    let chunks = [];

    if (totalPages > 100) {
      console.log(`� Large document detected (${totalPages} pages), using intelligent chunking...`);
      chunks = await processLargeDocument(text, filename, totalPages);
    } else {
      console.log(`� Standard document (${totalPages} pages), using standard processing...`);
      chunks = await processStandardDocument(text, filename, totalPages);
    }

    // Filter and validate chunks
    chunks = chunks.filter(chunk =>
      chunk.text.length > 100 && // Minimum meaningful content
      !isJunkContent(chunk.text) // Filter out headers, footers, page numbers
    );

    // Safety check: If we still have very large chunks, force split them
    const finalChunks = [];
    for (const chunk of chunks) {
      if (chunk.text.length > 3000) {
        console.log(`⚠️ Large chunk detected (${chunk.text.length} chars), splitting...`);

        // Split large chunk into smaller ones
        const maxSize = 1500;
        for (let i = 0; i < chunk.text.length; i += maxSize) {
          const subChunk = chunk.text.substring(i, i + maxSize);
          if (subChunk.trim().length > 100) {
            finalChunks.push({
              ...chunk,
              id: `${chunk.id}_split_${Math.floor(i / maxSize) + 1}`,
              text: subChunk.trim(),
            });
          }
        }
      } else {
        finalChunks.push(chunk);
      }
    }
    chunks = finalChunks;

    // Limit chunks for performance (keep most relevant ones)
    if (chunks.length > 200) {
      console.log(`📊 Too many chunks (${chunks.length}), selecting most relevant...`);
      chunks = selectMostRelevantChunks(chunks, 200);
    }

    console.log(`✅ Created ${chunks.length} content chunks`);
    chunks.forEach((chunk, index) => {
      if (index < 10) { // Show first 10 for debugging
        console.log(`   Chunk ${index + 1}: ${chunk.text.length} chars, tag: ${chunk.tag}, page: ${chunk.page}`);
      }
    });

    if (chunks.length > 10) {
      console.log(`   ... and ${chunks.length - 10} more chunks`);
    }

    // Store in memory
    processedContent = chunks;

    // Clean up uploaded file (only for multipart uploads)
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (e) {
        console.log('Note: Could not delete temp file (may not exist)');
      }
    }

    console.log(`✅ PDF processed: ${chunks.length} pages extracted`);

    res.json({
      success: true,
      message: `PDF processed successfully. Extracted ${chunks.length} pages.`,
      chunks: chunks,
      totalPages: chunks.length,
    });

  } catch (error) {
    console.error('❌ PDF processing error:', error);
    res.status(500).json({
      error: 'Failed to process PDF',
      details: error.message,
    });
  }
});

// Hugging Face-only conversational Q&A with clear error feedback
app.post('/api/answer-question', async (req, res) => {
  const requestId = Date.now();
  console.log(`🌐 [${requestId}] POST /api/answer-question - Request received`);

  try {
    const { question, history } = req.body;
    console.log(`❓ [${requestId}] Question: "${question}"`);
    console.log(`📊 [${requestId}] Request body:`, { question: question?.substring(0, 100), historyLength: history?.length || 0 });
    console.log(`🔄 [${requestId}] Starting processing...`);

    if (!question) {
      console.log(`❌ [${requestId}] Bad request: No question provided`);
      return res.status(400).json({
        success: false,
        error: 'Question is required',
        userMessage: 'Please provide a question.'
      });
    }

    console.log(`🔍 [${requestId}] Question validation passed`);

    // Quick response for common questions (bypass AI for speed)
    const quickResponse = getQuickResponse(question);
    if (quickResponse) {
      console.log(`⚡ [${requestId}] Using quick response`);
      return res.json({
        success: true,
        question: question,
        answer: quickResponse,
        conversational: true
      });
    }

    // Check for language commands first
    const languageCommand = detectLanguageCommand(question);
    if (languageCommand) {
      if (languageCommand === 'help') {
        return res.json({
          success: true,
          question: question,
          answer: getTranslation('languageHelp'),
          conversational: true,
          provider: 'language_system',
          currentLanguage: currentLanguage
        });
      } else {
        // Change language
        const oldLanguage = currentLanguage;
        currentLanguage = languageCommand;
        console.log(`🌍 Language changed from ${oldLanguage} to ${currentLanguage}`);

        return res.json({
          success: true,
          question: question,
          answer: getTranslation('languageChanged'),
          conversational: true,
          provider: 'language_system',
          currentLanguage: currentLanguage,
          languageChanged: true
        });
      }
    }

    // Check if we have processed content
    console.log(`📄 [${requestId}] Checking processed content: ${processedContent.length} chunks`);
    if (processedContent.length === 0) {
      console.log(`❌ [${requestId}] No PDF content available`);
      return res.json({
        success: false,
        question: question,
        error: 'No PDF uploaded',
        userMessage: 'No prospectus content available.',
        conversational: true,
        currentLanguage: currentLanguage
      });
    }

    // Find relevant content using enhanced semantic search
    console.log(`🔍 [${requestId}] Starting content search...`);
    const relevantChunks = await findRelevantContentEnhanced(question, processedContent);
    console.log(`📊 [${requestId}] Found ${relevantChunks.length} relevant chunks`);

    if (relevantChunks.length === 0) {
      console.log(`❌ [${requestId}] No relevant content found`);
      return res.json({
        success: false,
        question: question,
        error: 'No relevant content found',
        userMessage: "Unable to find information about that topic in the prospectus.",
        conversational: true
      });
    }

    // Check memory usage before AI processing
    const memoryBefore = process.memoryUsage();
    console.log(`💾 [${requestId}] Memory before AI: ${Math.round(memoryBefore.heapUsed / 1024 / 1024)}MB`);

    if (memoryBefore.heapUsed > 400 * 1024 * 1024) { // 400MB threshold
      console.log(`⚠️ [${requestId}] High memory usage detected, forcing garbage collection`);
      if (global.gc) {
        global.gc();
        const memoryAfterGC = process.memoryUsage();
        console.log(`🗑️ [${requestId}] Memory after GC: ${Math.round(memoryAfterGC.heapUsed / 1024 / 1024)}MB`);
      }
    }

    // Generate answer using Hugging Face
    console.log(`🤖 [${requestId}] Starting AI answer generation...`);
    const startTime = Date.now();

    const answer = await generateAnswerWithHuggingFace(question, relevantChunks, history);

    const processingTime = Date.now() - startTime;
    console.log(`✅ [${requestId}] Answer generated in ${processingTime}ms`);

    const response = {
      success: true,
      question: question,
      answer: answer,
      conversational: true
    };

    console.log(`🚀 [${requestId}] Sending response`);
    res.json(response);

  } catch (error) {
    console.error(`❌ [${requestId}] Hugging Face Q&A error:`, error.message);
    console.error(`🔍 [${requestId}] Error type: ${error.name}`);
    if (error.response?.status) {
      console.error(`🌐 [${requestId}] HTTP Status: ${error.response.status}`);
    }

    // Don't log full stack trace to reduce noise, but log key details
    console.error(`📍 [${requestId}] Error occurred in Q&A processing`);

    // Ensure question is available (fallback from req.body)
    const questionForResponse = question || req.body?.question || 'Unknown question';

    res.status(500).json({
      success: false,
      question: questionForResponse,
      error: error.message,
      userMessage: "Unable to process your question at this time.",
      conversational: true
    });
  }
});

// Get processed content
app.get('/api/content', (req, res) => {
  res.json({
    success: true,
    totalChunks: processedContent.length,
    chunks: processedContent.map(chunk => ({
      id: chunk.id,
      page: chunk.page,
      filename: chunk.filename,
      textPreview: chunk.text.substring(0, 100) + '...',
      timestamp: chunk.timestamp
    }))
  });
});


// REMOVED: Demo data function - use real PDF uploads only

// Sync content from Firestore to backend memory (for when Flutter uploads to Firestore)
app.post('/api/sync-from-firestore', async (req, res) => {
  console.log(`🌐 POST /api/sync-from-firestore - Syncing Firestore content to backend`);

  try {
    const { chunks } = req.body;

    if (!chunks || !Array.isArray(chunks)) {
      return res.status(400).json({
        success: false,
        error: 'Chunks array is required'
      });
    }

    // Convert Firestore format to backend format
    const backendChunks = chunks.map(chunk => ({
      id: chunk.id || `chunk_${Date.now()}`,
      page: chunk.page || 1,
      text: chunk.text || '',
      status: 'approved',
      tag: chunk.tag || 'General',
      timestamp: chunk.timestamp || new Date().toISOString(),
      filename: chunk.filename || 'firestore_content.pdf',
    }));

    // Store in backend memory
    processedContent = backendChunks;

    console.log(`✅ Synced ${backendChunks.length} chunks from Firestore to backend memory`);

    res.json({
      success: true,
      message: 'Content synced from Firestore successfully',
      totalChunks: processedContent.length,
      syncedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Firestore sync error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to sync from Firestore',
      details: error.message
    });
  }
});

// PDF Summarization endpoint
app.post('/api/summarize-pdf', async (req, res) => {
  console.log(`🌐 POST /api/summarize-pdf - Request received`);

  try {
    const { type, section } = req.body;
    console.log(`📋 Summarize request: type="${type}", section="${section}"`);
    console.log(`📊 Request body:`, req.body);

    if (processedContent.length === 0) {
      return res.json({
        success: false,
        error: 'No PDF uploaded',
        userMessage: "No PDF content has been uploaded yet. Please upload a prospectus PDF first through the admin dashboard.",
        type: type || 'full',
        conversational: true
      });
    }

    let summary;
    if (type === 'section' && section) {
      summary = await generateSectionSummary(section, processedContent);
    } else {
      summary = await generateFullPDFSummary(processedContent);
    }

    console.log(`✅ ${type === 'section' ? 'Section' : 'Full PDF'} summary generated`);

    res.json({
      success: true,
      summary: summary,
      type: type || 'full',
      totalChunks: processedContent.length,
      conversational: true
    });

  } catch (error) {
    console.error('❌ Summarization error:', error);

    res.status(500).json({
      success: false,
      error: 'Failed to generate summary',
      userMessage: error.message, // This now contains user-friendly messages
      type: type || 'full',
      conversational: true,
      timestamp: new Date().toISOString()
    });
  }
});

// Generate section summary
async function generateSectionSummary(sectionTopic, contentChunks) {
  try {
    // Find relevant chunks for the section
    const relevantChunks = await findRelevantContent(sectionTopic, contentChunks);

    if (relevantChunks.length === 0) {
      return "Unable to find information about that topic.";
    }

    const context = relevantChunks
      .map(chunk => chunk.text)
      .join('\n\n');

    const prompt = `Please provide a comprehensive summary of the "${sectionTopic}" section from this university prospectus. Focus on the key information that prospective students would need to know.

CONTENT TO SUMMARIZE:
${context}

Please provide a clear, well-organized summary that covers:
1. Main points and key information
2. Important details and requirements
3. Any deadlines, costs, or procedures mentioned
4. Contact information if provided

Keep the summary conversational and helpful for prospective students.`;

    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "You are a helpful university admissions assistant. Provide clear, comprehensive summaries of prospectus sections."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: 800,
      temperature: 0.3,
    });

    return completion.choices[0]?.message?.content?.trim() ||
      `Here's what I found about ${sectionTopic}:\n\n${context.substring(0, 500)}...`;

  } catch (error) {
    console.error('❌ Error generating section summary:', error);

    // Fallback to basic summary
    const relevantChunks = await findRelevantContent(sectionTopic, contentChunks);
    const context = relevantChunks
      .map(chunk => chunk.text.substring(0, 200))
      .join('\n\n');

    return `Here's what I found about ${sectionTopic}:\n\n${context}`;
  }
}

// Generate full PDF summary using Hugging Face only
async function generateFullPDFSummary(contentChunks) {
  try {
    if (!contentChunks || contentChunks.length === 0) {
      throw new Error('No PDF content available to summarize');
    }

    // Get a representative sample of content from different parts of the PDF
    const sampleChunks = contentChunks
      .filter((_, index) => index % Math.max(1, Math.floor(contentChunks.length / 8)) === 0)
      .slice(0, 8);

    const context = sampleChunks
      .map(chunk => `Page ${chunk.page}: ${chunk.text}`)
      .join('\n\n');

    console.log('🤗 Generating PDF summary with Hugging Face...');
    return await generateSummaryWithHuggingFace(context);

  } catch (error) {
    console.error('❌ Error generating Hugging Face summary:', error);

    // Throw error with user-friendly message
    let userMessage = "I'm having trouble generating the summary. ";

    if (error.message.includes('rate limit') || error.message.includes('quota')) {
      userMessage += "The AI service is temporarily overloaded. Please try again in a few minutes.";
    } else if (error.message.includes('network') || error.message.includes('timeout')) {
      userMessage += "There's a network connection issue. Please check your internet connection and try again.";
    } else if (error.message.includes('model') || error.message.includes('loading')) {
      userMessage += "The AI model is still loading. Please wait a moment and try again.";
    } else {
      userMessage += "Please try again or contact support if the issue persists.";
    }

    throw new Error(userMessage);
  }
}

// OpenAI summary generation
async function generateSummaryWithOpenAI(context) {
  const prompt = `Please provide a comprehensive summary of this university prospectus document. This summary will help prospective students understand what the university offers.

PROSPECTUS CONTENT SAMPLE:
${context}

Please provide a well-structured summary that covers:

1. **University Overview**: What kind of institution this is
2. **Academic Programs**: Main programs and degrees offered
3. **Admission Requirements**: Key requirements for entry
4. **Fees and Costs**: Tuition and other costs
5. **Application Process**: How to apply and important deadlines
6. **Contact Information**: How to get more information

Make the summary comprehensive but easy to understand, as it will be read aloud to visually impaired students.`;

  const completion = await openai.chat.completions.create({
    model: process.env.OPENAI_MODEL || "gpt-3.5-turbo",
    messages: [
      {
        role: "system",
        content: "You are a helpful university admissions assistant. Provide comprehensive, well-structured summaries of university prospectus documents."
      },
      {
        role: "user",
        content: prompt
      }
    ],
    max_tokens: 1000,
    temperature: 0.3,
  });

  return completion.choices[0]?.message?.content?.trim() ||
    "This prospectus contains information about academic programs, admission requirements, fees, and application procedures. For specific details, please ask targeted questions.";
}

// Hugging Face summary generation
async function generateSummaryWithHuggingFace(context) {
  console.log('🤗 Generating summary with Hugging Face...');

  // Create a structured prompt for better summarization
  const structuredText = `University Prospectus Summary Request: ${context}`;

  const summary = await summarizeWithHuggingFace(structuredText);

  // Enhance the summary with structure
  return `📋 **University Prospectus Summary** (Generated with Hugging Face AI)

${summary}

💡 **For More Information**: Ask specific questions about programs, fees, admission requirements, or application deadlines.

🤗 **Powered by**: Hugging Face BART model (free AI service)`;
}

// Extract admission information from processed content
app.post('/api/admission-info', async (req, res) => {
  console.log(`🌐 POST /api/admission-info - Request received`);

  try {
    if (processedContent.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'No document processed',
        message: 'Please upload a PDF document first to extract admission information.'
      });
    }

    console.log(`📋 Extracting admission info from ${processedContent.length} chunks`);

    // Keywords to identify admission-related content
    const admissionKeywords = [
      'admission', 'admissions', 'entry', 'requirements', 'requirement',
      'application', 'apply', 'eligibility', 'qualify', 'qualification',
      'entrance', 'enroll', 'enrollment', 'registration', 'register',
      'fee', 'fees', 'cost', 'tuition', 'payment', 'scholarship',
      'deadline', 'date', 'semester', 'academic year', 'intake'
    ];

    // Find relevant chunks
    const relevantChunks = processedContent.filter(chunk => {
      const text = chunk.content.toLowerCase();
      return admissionKeywords.some(keyword => text.includes(keyword));
    });

    if (relevantChunks.length === 0) {
      return res.json({
        success: true,
        admissionInfo: {
          message: 'No specific admission information found in the document.',
          generalInfo: 'Please contact the institution directly for admission details.'
        }
      });
    }

    console.log(`📄 Found ${relevantChunks.length} relevant chunks for admission info`);

    // Extract structured admission information
    const admissionInfo = {
      requirements: [],
      fees: [],
      deadlines: [],
      procedures: [],
      contact: [],
      general: []
    };

    relevantChunks.forEach(chunk => {
      const text = chunk.content.toLowerCase();
      const originalText = chunk.content;

      // Categorize content
      if (text.includes('requirement') || text.includes('eligibility') || text.includes('qualify')) {
        admissionInfo.requirements.push(originalText);
      } else if (text.includes('fee') || text.includes('cost') || text.includes('tuition') || text.includes('payment')) {
        admissionInfo.fees.push(originalText);
      } else if (text.includes('deadline') || text.includes('date') || text.includes('semester') || text.includes('intake')) {
        admissionInfo.deadlines.push(originalText);
      } else if (text.includes('application') || text.includes('apply') || text.includes('registration') || text.includes('register')) {
        admissionInfo.procedures.push(originalText);
      } else if (text.includes('contact') || text.includes('phone') || text.includes('email') || text.includes('address')) {
        admissionInfo.contact.push(originalText);
      } else {
        admissionInfo.general.push(originalText);
      }
    });

    // Clean up empty arrays and limit content length
    Object.keys(admissionInfo).forEach(key => {
      admissionInfo[key] = admissionInfo[key]
        .slice(0, 5) // Limit to 5 items per category
        .map(text => text.length > 300 ? text.substring(0, 300) + '...' : text);

      if (admissionInfo[key].length === 0) {
        delete admissionInfo[key];
      }
    });

    console.log(`✅ Admission info extracted successfully`);
    console.log(`📊 Categories found: ${Object.keys(admissionInfo).join(', ')}`);

    res.json({
      success: true,
      admissionInfo: admissionInfo,
      totalChunks: relevantChunks.length,
      message: 'Admission information extracted successfully'
    });

  } catch (error) {
    console.error('❌ Admission info extraction error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to extract admission information',
      message: error.message
    });
  }
});


app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 VIAS Server running on port ${port}`);
  console.log(`🤗 AI Provider: HUGGING FACE (FREE)`);
  console.log(`🌐 Language Support: English & Swahili`);
  console.log(`📄 Upload PDFs to: /api/process-pdf`);
  console.log(`❓ Ask questions at: /api/answer-question`);
  console.log(`📋 Summarize PDFs at: /api/summarize-pdf`);
  console.log(`🎓 Get admission info: /api/admission-info`);
  console.log(`🌐 Language API: /api/language`);
});
