# GeminiLite Test

A minimal static website hosted on GitHub Pages to test integration with the Gemini 2.0 Flash Lite API via Google Apps Script.

## Setup Instructions

1. **Clone the Repository**:

   ```text
   git clone https://github.com/UTOXAS/GeminiLiteTest.git
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
   - Set the Gemini API key:
     - In the Apps Script Editor, go to **Editor** > **Code.gs**.
     - Select the `setGeminiApiKey` function from the function dropdown and click **Run**.
     - Enter your API key when prompted and confirm it’s saved.
   - Deploy as a web app:
     - Click **Deploy** > **New Deployment** > **Web app**.
     - Set **Execute as**: Me.
     - Set **Who has access**: Anyone.
     - Click **Deploy** and copy the web app URL for manual verification.

4. **Install clasp for Automated Deployment**:
   - Install Node.js if not already installed.
   - Install clasp globally:

     ```text
     npm install -g @google/clasp
     ```

   - Log in to clasp:

     ```text
     clasp login
     ```

   - Create `.clasp.json` in the project root:

     ```text
     clasp create --title "GeminiLiteTestBackend"
     ```

     Follow prompts to select the script type (Standalone) and note the Script ID.

5. **Deploy Apps Script and Update Frontend**:
   - Run the deployment script:

     ```text
     .\deploy-apps-script.ps1
     ```

     This pushes the code, deploys the web app, updates `docs/js/config.js` with the web app URL, and commits changes.
   - Verify the deployment by checking `clasp-deploy-output.log` for the web app URL.

6. **Deploy to GitHub Pages**:
   - Commit and push changes (if not done by the script):

     ```text
     git add .
     git commit -m "Initial project setup"
     git push origin main
     ```

   - Enable GitHub Pages:
     - Go to repository **Settings** > **Pages**.
     - Set **Source** to **Deploy from a branch**.
     - Select **Branch**: `main`, **Folder**: `/docs`.
     - Click **Save**.

7. **Test the Website**:
   - Visit `https://<your-username>.github.io/GeminiLiteTest`.
   - Enter a query (e.g., "What is the capital of France?") and click "Submit."
   - Verify the response from the Gemini API.
   - If CORS errors occur, check the Apps Script logs:
     - In the Apps Script Editor, go to **View** > **Logs**.
     - Ensure `doGet` is handling `OPTIONS` requests.

## Project Structure

```text
GeminiLiteTest/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── apps-script/
│   ├── Code.gs
│   └── appsscript.json
├── docs/
│   ├── index.html
│   ├── css/
│   │   └── styles.css
│   └── js/
│       ├── config.js
│       └── script.js
├── .gitignore
├── deploy-apps-script.ps1
└── README.md
```

## Notes

- The Gemini 2.0 Flash Lite API is text-only and cost-efficient, suitable for lightweight applications.
- Ensure your Google Cloud project has the Gemini API enabled.
- Monitor API usage to stay within free tier limits.
- If deployment fails, check `clasp-deploy-output.log` and Apps Script logs for errors.
