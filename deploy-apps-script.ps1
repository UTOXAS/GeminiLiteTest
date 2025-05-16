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

# List and delete all but the most recent deployment
Write-Host "Listing existing deployments..."
$deploymentsOutput = clasp deployments 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to list deployments: $deploymentsOutput"
    exit 1
}

# Parse deployments (format: - <deploymentId> @<version>)
$deployments = $deploymentsOutput -split "`n" | Where-Object { $_ -match '^- ([\w-]+) @(\d+)' } | ForEach-Object {
    $matches = $_ -match '^- ([\w-]+) @(\d+)'
    [PSCustomObject]@{
        DeploymentId = $Matches[1]
        Version = [int]$Matches[2]
    }
} | Sort-Object Version -Descending

Write-Host "Found $($deployments.Count) deployments."

# Delete all but the most recent deployment
if ($deployments.Count -gt 1) {
    $deploymentsToDelete = $deployments | Select-Object -Skip 1
    foreach ($dep in $deploymentsToDelete) {
        Write-Host "Deleting old deployment: $($dep.DeploymentId) @ Version $($dep.Version)"
        $undeployOutput = clasp undeploy --force $dep.DeploymentId 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully deleted deployment: $($dep.DeploymentId)"
        } else {
            Write-Warning "Failed to delete deployment $($dep.DeploymentId): $undeployOutput. Continuing..."
        }
    }
} elseif ($deployments.Count -eq 0) {
    Write-Host "No existing deployments found. Proceeding with new deployment."
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
Write-Host "Logging clasp deploy output..."
$deployOutput | Out-File -FilePath "clasp-deploy-output.log" -Encoding utf8
Write-Host "Clasp deploy output logged to clasp-deploy-output.log"

# Extract deployment ID from output
Write-Host "Extracting deployment ID..."
$match = $deployOutput | Select-String "Deployed ([A-Za-z0-9_-]+) @\d+"
if ($match) {
    $deployId = $match.Matches[0].Groups[1].Value
} else {
    Write-Error "Could not find deployment ID in clasp output: $deployOutput. Check clasp-deploy-output.log."
    exit 1
}

# Validate deployment ID
if (-not $deployId -or $deployId.Length -lt 30) {
    Write-Error "Invalid deployment ID extracted: $deployId"
    exit 1
}

$webAppUrl = "https://script.google.com/macros/s/$deployId/exec"
Write-Host "Web App URL: $webAppUrl"

# Verify web app accessibility with OPTIONS request
Write-Host "Verifying web app accessibility with OPTIONS request..."
try {
    $response = Invoke-WebRequest -Uri $webAppUrl -Method OPTIONS -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "Web app responds to OPTIONS request successfully."
    }
} catch {
    Write-Warning "OPTIONS request verification failed: $_"
}

# Verify web app accessibility with POST request
Write-Host "Verifying web app accessibility with POST request..."
try {
    $response = Invoke-WebRequest -Uri $webAppUrl -Method POST -Body '{"query":"test"}' -ContentType 'application/json' -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "Web app is accessible and responds to POST request."
    } else {
        Write-Warning "Web app returned status code: $($response.StatusCode)"
    }
} catch {
    Write-Warning "POST request verification failed: $_"
}

# Update config.js file
Write-Host "Updating config.js file..."
Set-Content -Path docs/js/config.js -Value "const APPS_SCRIPT_URL = '$webAppUrl';"
Write-Host "config.js updated successfully."

Write-Host "Deployment complete. Note: GitHub commit and push skipped per user request. Manually commit changes if needed."