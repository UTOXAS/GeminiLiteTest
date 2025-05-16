const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent';

// Helper to create CORS-enabled response
function createCorsResponse(content = '') {
  const output = ContentService.createTextOutput(content)
    .setMimeType(ContentService.MimeType.JSON);
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '3600'
  };
  output.setHeaders(headers);
  debugHeaders(headers);
  return output;
}

// Debug headers for logging
function debugHeaders(headers) {
  Logger.log('Response Headers: ' + JSON.stringify(headers));
}

// Handle all HTTP requests
function doGet(e) {
  // Handle CORS preflight OPTIONS request
  const method = e?.method || e?.parameter?.method || 'GET';
  if (method.toUpperCase() === 'OPTIONS') {
    Logger.log('Handling OPTIONS request for CORS preflight');
    return createCorsResponse();
  }

  // Handle standard GET request with hardcoded query
  Logger.log('Handling GET request for hardcoded Gemini query');
  const hardcodedQuery = 'What is the capital of France?';
  let responseText = '';
  let isError = false;

  try {
    responseText = callGeminiAPI(hardcodedQuery);
    Logger.log('Successful Gemini API response for GET request');
  } catch (error) {
    responseText = `Error: ${error.message}`;
    isError = true;
    Logger.log('Error in doGet: ' + error.message);
  }

  // Return JSON response
  const response = {
    query: hardcodedQuery,
    response: responseText,
    error: isError
  };
  return createCorsResponse(JSON.stringify(response));
}

// Handle POST requests
function doPost(e) {
  // Handle CORS preflight OPTIONS request
  const method = e?.method || e?.parameter?.method || 'POST';
  if (method.toUpperCase() === 'OPTIONS') {
    Logger.log('Handling OPTIONS request for CORS preflight');
    return createCorsResponse();
  }

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

  // Append API key as query parameter
  const url = `${GEMINI_API_URL}?key=${API_KEY}`;
  Logger.log('Calling Gemini API with URL: ' + url);

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
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };

  const response = UrlFetchApp.fetch(url, options);
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