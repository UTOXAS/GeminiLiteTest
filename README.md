# GeminiLite Test

A minimal static website hosted on GitHub Pages to test integration with the Gemini 2.0 Flash Lite API via Google Apps Script.

## Setup Instructions

1. **Clone the Repository**:

   ```powershell
   git clone https://github.com/<your-username>/GeminiLiteTest.git
   cd GeminiLiteTest
   ```

2. **Obtain a Gemini API Key**:
   - Go to [Google AI Studio](https://aistudio.google.com).
   - Create a new project and generate an API key.
   - Copy the API key for use in Google Apps Script.

3. **Set Up Google Apps Script**:
   - Open [Google Apps Script](https://script.google.com).
   - Create a new project named "GeminiLiteTestBackend."
   - Copy the contents of `apps-script/Code.gs` and `apps-script/appsscript.json` into the script editor.
   - In `Code.gs`, replace `YOUR_GEMINI_API_KEY` with your API key.
   - Deploy as a web app:
     - Click **Deploy** > **New Deployment** > **Web app**.
     - Set **Execute as**: Me.
     - Set **Who has access**: Anyone.
     - Click **Deploy** and copy the web app URL.

4. **Update Frontend**:
   - In `docs/js/script.js`, replace `YOUR_APPS_SCRIPT_URL` with the web app URL from step 3.

5. **Deploy to GitHub Pages**:
   - Commit and push changes:

     ```powershell
     git add .
     git commit -m "Initial project setup"
     git push origin main
     ```

   - Enable GitHub Pages:
     - Go to repository **Settings** > **Pages**.
     - Set **Source** to **Deploy from a branch**.
     - Select **Branch**: `main`, **Folder**: `/docs`.
     - Click **Save**.

6. **Test the Website**:
   - Visit `https://<your-username>.github.io/GeminiLiteTest`.
   - Enter a query (e.g., "What is the capital of France?") and click "Submit."
   - Verify the response from the Gemini API.

## Project Structure

```
GeminiLiteTest/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── docs/
│   ├── index.html
│   ├── css/
│   │   └── styles.css
│   └── js/
│       └── script.js
├── apps-script/
│   ├── Code.gs
│   └── appsscript.json
├── .gitignore
└── README.md
```

## Notes

- The Gemini 2.0 Flash Lite API is text-only and cost-efficient, suitable for lightweight applications.
- Ensure your Google Cloud project has the Gemini API enabled.
- Monitor API usage to stay within free tier limits.
