# deploy-apps-script.ps1
# Automates pushing and deploying Google Apps Script code, updating config.js with the web app URL

# Ensure clasp is installed
if (-not (Get-Command clasp -ErrorAction SilentlyContinue)) {
    Write-Error "clasp is not installed. Please run 'npm install -g @google/clasp' and try again."
    exit 1
}

# Ensure .clasp.json exists
if (-not (Test-Path .clasp.json)) {
    Write-Error ".clasp.json not found. Please configure clasp with your Script ID."
    exit 1
}

# Push local Apps Script code to Google
Write-Host "Pushing Apps Script code to Google..."
clasp push
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push Apps Script code."
    exit 1
}

# Deploy the Apps Script project as a web app
Write-Host "Deploying Apps Script as web app..."
$deployOutput = clasp deploy --description "GeminiLiteTestBackend" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to deploy Apps Script: $deployOutput"
    exit 1
}

# Log raw output for debugging
$deployOutput | Out-File -FilePath "clasp-deploy-output.log" -Encoding utf8
Write-Host "Clasp deploy output logged to clasp-deploy-output.log"

# Extract deployment ID from output
$deployId = $deployOutput | Select-String "Deployed (\w+) @\d+" | ForEach-Object { $_.Matches.Groups[1].Value }
if (-not $deployId) {
    Write-Error "Could not extract deployment ID from clasp output. Check clasp-deploy-output.log for details."
    exit 1
}

# Get the web app URL
$scriptId = (Get-Content .clasp.json | ConvertFrom-Json).scriptId
$webAppUrl = "https://script.google.com/macros/s/$deployId/exec"
Write-Host "Web App URL: $webAppUrl"

# Update config.js file
Write-Host "Updating config.js file..."
Set-Content -Path docs/js/config.js -Value "const APPS_SCRIPT_URL = '$webAppUrl';"
Write-Host "config.js updated successfully."

# Commit changes to config.js
Write-Host "Committing config.js changes..."
git add docs/js/config.js
git commit -m "Update Apps Script URL in config.js" --no-verify
git push origin main
Write-Host "Deployment complete."