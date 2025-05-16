# deploy-apps-script.ps1
# Automates pushing and deploying Google Apps Script code, updating config.js with the web app URL

# Ensure clasp is installed
if (-not (Get-Command clasp -ErrorAction SilentlyContinue)) {
    Write-Error "clasp is not installed. Please run 'npm install -g @google/clasp' and try again."
    exit 1
}

# Ensure .clasp.json exists
if (-not (Test-Path .clasp.json)) {
    Write-Error ".clasp.json not found. Please run 'clasp login' and 'clasp create' or configure with your Script ID."
    exit 1
}

# Push local Apps Script code to Google
Write-Host "Pushing Apps Script code to Google..."
clasp push
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push Apps Script code."
    exit 1
}

# Create a new version
Write-Host "Creating new Apps Script version..."
$versionOutput = clasp version "Automated deployment for GeminiLiteTestBackend" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create new version: $versionOutput"
    exit 1
}

# Extract version number
$version = $versionOutput | Select-String "Version (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
if (-not $version) {
    Write-Error "Could not extract version number from clasp output."
    exit 1
}

# Deploy the Apps Script project as a web app with retry logic
Write-Host "Deploying Apps Script as web app (Version $version)..."
$maxRetries = 3
$retryCount = 0
$success = $false
while (-not $success -and $retryCount -lt $maxRetries) {
    $deployOutput = clasp deploy --versionNumber $version --description "GeminiLiteTestBackend v$version" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $success = $true
    } else {
        $retryCount++
        Write-Warning "Deployment attempt $retryCount failed: $deployOutput"
        if ($retryCount -lt $maxRetries) {
            Write-Host "Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
        }
    }
}

if (-not $success) {
    Write-Error "Failed to deploy Apps Script after $maxRetries attempts: $deployOutput"
    exit 1
}

# Log raw output for debugging
$deployOutput | Out-File -FilePath "clasp-deploy-output.log" -Encoding utf8
Write-Host "Clasp deploy output logged to clasp-deploy-output.log"

# Extract deployment ID
$deployId = $deployOutput | Select-String "Created deployment (\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }
if (-not $deployId) {
    Write-Error "Could not extract deployment ID from clasp output. Check clasp-deploy-output.log for details."
    exit 1
}

# Get the web app URL
$scriptId = (Get-Content .clasp.json | ConvertFrom-Json).scriptId
$webAppUrl = "https://script.google.com/macros/s/$deployId/exec"
Write-Host "Web App URL: $webAppUrl"

# Verify web app accessibility
Write-Host "Verifying web app accessibility..."
try {
    $response = Invoke-WebRequest -Uri $webAppUrl -Method OPTIONS -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "Web app is accessible and responds to OPTIONS request."
    }
} catch {
    Write-Warning "Failed to verify web app: $_"
}

# Update config.js file
Write-Host "Updating config.js file..."
Set-Content -Path docs/js/config.js -Value "const APPS_SCRIPT_URL = '$webAppUrl';"
Write-Host "config.js updated successfully."

# Commit changes to config.js
Write-Host "Committing config.js changes..."
git add docs/js/config.js
git commit -m "Update Apps Script URL in config.js for deployment $deployId" --no-verify
git push origin main
Write-Host "Deployment complete."