const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent';

function doGet(e) {
  // Handle preflight OPTIONS requests for CORS
  return ContentService.createTextOutput('')
    .setMimeType(ContentService.MimeType.JSON)
    .setHeaders({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Max-Age': '3600'
    });
}

function doPost(e) {
  try {
    // Set CORS headers for all responses
    const output = ContentService.createTextOutput();
    output.setMimeType(ContentService.MimeType.JSON);
    output.setHeaders({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });

    const data = JSON.parse(e.postData.contents);
    const query = data.query;

    if (!query) {
      return output.setContent(JSON.stringify({ error: 'Query is required' }));
    }

    const response = callGeminiAPI(query);
    return output.setContent(JSON.stringify({ response: response }));
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({ error: error.message }))
      .setMimeType(ContentService.MimeType.JSON)
      .setHeaders({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      });
  }
}

function callGeminiAPI(query) {
  const API_KEY = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  if (!API_KEY) {
    throw new Error('Gemini API key not configured');
  }

  const payload = {
    contents: [
      {
        parts: [
          { text: query }
        ]
      }
    ]
  };

  const options = {
    method: 'POST',
    contentType: 'application/json',
    headers: {
      'Authorization': `Bearer ${API_KEY}`
    },
    payload: JSON.stringify(payload)
  };

  const response = UrlFetchApp.fetch(GEMINI_API_URL, options);
  const json = JSON.parse(response.getContentText());
  
  if (json.candidates && json.candidates[0].content) {
    return json.candidates[0].content.parts[0].text;
  } else {
    throw new Error('No valid response from Gemini API');
  }
}