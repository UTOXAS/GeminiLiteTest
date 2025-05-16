# deploy-apps-script.ps1
# Automates pushing and deploying Google Apps Script code, updating .env with the web app URL

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
$deployId = $deployOutput | Select-String "- (\w+) @HEAD" | ForEach-Object { $_.Matches.Groups[1].Value }
if (-not $deployId) {
    Write-Error "Could not extract deployment ID from clasp output. Check clasp-deploy-output.log for details."
    exit 1
}

# Get the web app URL
$scriptId = (Get-Content .clasp.json | ConvertFrom-Json).scriptId
$webAppUrl = "https://script.google.com/macros/s/$deployId/exec"
Write-Host "Web App URL: $webAppUrl"

# Update .env file
Write-Host "Updating .env file..."
Set-Content -Path .env -Value "APPS_SCRIPT_URL=$webAppUrl"
Copy-Item .env docs\.env
Write-Host ".env updated successfully."

# Commit changes to .env
Write-Host "Committing .env changes to docs..."
git add docs\.env
git commit -m "Update Apps Script URL in .env" --no-verify
git push origin main
Write-Host "Deployment complete."