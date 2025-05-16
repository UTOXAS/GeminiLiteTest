const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent';

// Helper to create CORS-enabled response
function createCorsResponse(content = '') {
  const output = ContentService.createTextOutput(content)
    .setMimeType(ContentService.MimeType.JSON);
  output.setHeaders({
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '3600'
  });
  return output;
}

// Handle OPTIONS for CORS preflight
function doGet(e) {
  Logger.log('Handling OPTIONS request for CORS preflight');
  return createCorsResponse();
}

// Handle POST requests
function doPost(e) {
  try {
    Logger.log('Received POST request: ' + (e.postData?.contents || 'No content'));
    if (!e.postData?.contents) {
      Logger.log('Error: No post data received');
      return createCorsResponse(JSON.stringify({ error: 'No post data received' }));
    }

    const data = JSON.parse(e.postData.contents);
    const query = data.query;

    if (!query) {
      Logger.log('Error: Query is missing');
      return createCorsResponse(JSON.stringify({ error: 'Query is required' }));
    }

    const response = callGeminiAPI(query);
    Logger.log('Successful Gemini API response');
    return createCorsResponse(JSON.stringify({ response: response }));
  } catch (error) {
    Logger.log('Error in doPost: ' + error.message);
    return createCorsResponse(JSON.stringify({ error: error.message }));
  }
}

function callGeminiAPI(query) {
  const API_KEY = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  if (!API_KEY) {
    Logger.log('Error: Gemini API key not configured');
    throw new Error('Gemini API key not configured. Run setGeminiApiKey() to configure.');
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
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };

  const response = UrlFetchApp.fetch(GEMINI_API_URL, options);
  const responseCode = response.getResponseCode();
  const responseText = response.getContentText();

  if (responseCode !== 200) {
    Logger.log('Gemini API error: ' + responseText);
    throw new Error(`Gemini API returned ${responseCode}: ${responseText}`);
  }

  const json = JSON.parse(responseText);
  if (json.candidates && json.candidates[0].content && json.candidates[0].content.parts[0].text) {
    return json.candidates[0].content.parts[0].text;
  } else {
    Logger.log('Invalid Gemini API response: ' + responseText);
    throw new Error('No valid response from Gemini API');
  }
}

// Utility function to set API key
function setGeminiApiKey() {
  const ui = SpreadsheetApp.getUi();
  const response = ui.prompt('Enter your Gemini API Key:');
  const apiKey = response.getResponseText();
  if (apiKey) {
    PropertiesService.getScriptProperties().setProperty('GEMINI_API_KEY', apiKey);
    ui.alert('API Key saved successfully!');
  } else {
    ui.alert('No API Key provided.');
  }
}