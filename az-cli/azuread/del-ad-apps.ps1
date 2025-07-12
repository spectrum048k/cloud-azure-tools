# Azure AD App Registration Deletion Script
# Exit on errors
$ErrorActionPreference = "Stop"

param(
    [string]$DryRun = "true",        # Default to dry-run for safety
    [string]$FilterPattern = ""      # Optional filter pattern for app display names
)

# Color functions for output
function Write-Warning-Red($message) {
    Write-Host $message -ForegroundColor Red
}

function Write-Warning-Yellow($message) {
    Write-Host $message -ForegroundColor Yellow
}

function Write-Success-Green($message) {
    Write-Host $message -ForegroundColor Green
}

Write-Warning-Red "⚠️  WARNING: This script will DELETE Azure AD app registrations!"
Write-Warning-Yellow "Usage: .\del-ad-apps.ps1 [-DryRun true|false] [-FilterPattern 'pattern']"
Write-Warning-Yellow "  - DryRun: dry-run mode (default: true)"
Write-Warning-Yellow "  - FilterPattern: optional filter pattern for app names"
Write-Host ""

# Safety confirmation for non-dry-run mode
if ($DryRun -eq "false") {
    Write-Warning-Red "🚨 DESTRUCTIVE OPERATION - This will permanently DELETE app registrations!"
    Write-Host "Current tenant information:"
    
    try {
        $tenantInfo = az account show --query '{tenantId: tenantId, name: name}' -o table
        Write-Host $tenantInfo
    }
    catch {
        Write-Error "Failed to get tenant information. Exiting."
        exit 1
    }
    
    Write-Host ""
    $confirm = Read-Host "Type 'DELETE' in ALL CAPS to confirm this destructive operation"
    if ($confirm -ne "DELETE") {
        Write-Host "Operation cancelled for safety."
        exit 1
    }
}

# Login to your Azure account
Write-Host "Logging in to Azure..."
try {
    az login
    if ($LASTEXITCODE -ne 0) {
        throw "Login failed"
    }
}
catch {
    Write-Error "Failed to login to Azure. Exiting."
    exit 1
}

# Set your default subscription
# az account set --subscription "your-subscription-id"

Write-Host "Retrieving app registrations..."

# Get a list of all app registrations with additional details
try {
    if ($FilterPattern) {
        Write-Host "Filtering apps by pattern: $FilterPattern"
        $appListJson = az ad app list --query "[?contains(displayName, '$FilterPattern')].{appId: appId, displayName: displayName}" -o json
    } else {
        $appListJson = az ad app list --query "[].{appId: appId, displayName: displayName}" -o json
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to retrieve app list"
    }
    
    $appList = $appListJson | ConvertFrom-Json
}
catch {
    Write-Error "Failed to retrieve app registrations. Exiting."
    exit 1
}

# Check if any apps were found
$appCount = $appList.Count
if ($appCount -eq 0) {
    Write-Host "No app registrations found matching the criteria."
    exit 0
}

Write-Host "Found $appCount app registration(s):"
foreach ($app in $appList) {
    Write-Host "- $($app.displayName) ($($app.appId))"
}
Write-Host ""

if ($DryRun -eq "true") {
    Write-Success-Green "🔍 DRY RUN MODE - No apps will be deleted"
    Write-Host "The following apps would be deleted:"
    foreach ($app in $appList) {
        Write-Host "  ❌ $($app.displayName) ($($app.appId))"
    }
    Write-Host ""
    Write-Host "To actually delete these apps, run: .\del-ad-apps.ps1 -DryRun false"
    exit 0
}

# Actually delete the apps (non-dry-run mode)
Write-Warning-Red "🗑️  Deleting app registrations..."
$deletedCount = 0
$failedCount = 0

foreach ($app in $appList) {
    $appId = $app.appId
    $displayName = $app.displayName
    
    Write-Host "Deleting: $displayName ($appId)"
    
    try {
        az ad app delete --id $appId 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success-Green "  ✅ Successfully deleted"
            $deletedCount++
        } else {
            throw "Delete command failed"
        }
    }
    catch {
        Write-Warning-Red "  ❌ Failed to delete"
        $failedCount++
    }
}

Write-Host ""
Write-Host "Summary:"
Write-Host "  Deleted: $deletedCount"
Write-Host "  Failed: $failedCount"
Write-Host "  Total: $appCount"
