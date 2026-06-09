// Example: Label Detection with Google Vision JS
//
// Prerequisites:
//   1. Build: bash scripts/build.sh
//   2. Set your API key: export GOOGLE_VISION_API_KEY="your-key-here"
//
// Usage:
//   node example/vision_example.mjs
//
// Or with an explicit image URL:
//   node example/vision_example.mjs "https://example.com/photo.jpg"

import { GoogleVision } from '../dist/node.js';

async function main() {
  const apiKey = process.env.GOOGLE_VISION_API_KEY;

  if (!apiKey) {
    console.error(
      'Error: GOOGLE_VISION_API_KEY environment variable not set.\n' +
      'Set it with: export GOOGLE_VISION_API_KEY="your-api-key"',
    );
    process.exit(1);
  }

  // Accept an image URL from command line, or use a default
  const imageUrl = process.argv[2] ||
    'https://www.snexplores.org/wp-content/uploads/sites/3/2019/11/860_main_beauty.png';

  console.log('Initializing Google Vision...');

  const vision = await GoogleVision.create();
  vision.withApiKey(apiKey);

  console.log(`\nAnalyzing image: ${imageUrl}\n`);

  try {
    // --- Label Detection ---
    console.log('--- Label Detection ---');
    const labels = await vision.image.labelDetection(imageUrl);

    if (labels && labels.length > 0) {
      labels.forEach((label, i) => {
        console.log(
          `  ${i + 1}. ${label.description} (score: ${(label.score * 100).toFixed(1)}%)`,
        );
      });
    } else {
      console.log('  No labels detected.');
    }

    // --- Safe Search Detection ---
    console.log('\n--- Safe Search Detection ---');
    const safeSearch = await vision.image.safeSearchDetection(imageUrl);

    if (safeSearch) {
      console.log(`  Adult:    ${safeSearch.adult}`);
      console.log(`  Spoof:    ${safeSearch.spoof}`);
      console.log(`  Medical:  ${safeSearch.medical}`);
      console.log(`  Violence: ${safeSearch.violence}`);
      console.log(`  Racy:     ${safeSearch.racy}`);
    } else {
      console.log('  No safe search results.');
    }

    // --- Text Detection ---
    console.log('\n--- Text Detection (OCR) ---');
    const texts = await vision.image.textDetection(imageUrl);

    if (texts && texts.length > 0) {
      console.log(`  Detected ${texts.length} text element(s).`);
      if (texts[0].description) {
        const preview = texts[0].description.slice(0, 100);
        console.log(`  First text: "${preview}${texts[0].description.length > 100 ? '...' : ''}"`);
      }
    } else {
      console.log('  No text detected.');
    }

    // --- Face Detection ---
    console.log('\n--- Face Detection ---');
    const faces = await vision.image.faceDetection(imageUrl);

    if (faces && faces.length > 0) {
      console.log(`  Detected ${faces.length} face(s).`);
      faces.forEach((face, i) => {
        const joy = face.joyLikelihood || 'UNKNOWN';
        const sorrow = face.sorrowLikelihood || 'UNKNOWN';
        console.log(`  Face ${i + 1}: joy=${joy}, sorrow=${sorrow}`);
      });
    } else {
      console.log('  No faces detected.');
    }

    console.log('\nAnalysis complete!');
  } catch (error) {
    // dart2js boxes Dart exceptions — unwrap to get the real error
    let msg = String(error);
    
    // Try to unwrap dart2js boxed exception
    if (error?.error) {
      const symbols = Object.getOwnPropertySymbols(error.error);
      const boxSym = symbols.find(s => s.toString().includes('jsBoxed'));
      
      if (boxSym) {
        const dartError = error.error[boxSym];
        // Dart errors have message in different properties depending on type
        msg = dartError?.message || 
              dartError?.f || 
              dartError?.toString() || 
              String(dartError);
      }
    } else if (error?.message) {
      msg = error.message;
    }
    
    console.error('Error during vision analysis:', msg);
    
    // For debugging: log full error structure (comment out in production)
    console.error('Full error object:', JSON.stringify(error, (key, value) => {
      if (typeof value === 'symbol') return value.toString();
      return value;
    }, 2));
    
    process.exit(1);
  }
}

main();
