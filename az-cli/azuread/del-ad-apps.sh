#!/bin/bash

# Exit on errors, undefined variables, and pipe failures
set -euo pipefail

# Configuration
dryrun="${1:-true}"  # Default to dry-run for safety
filter_pattern="${2:-}"  # Optional filter pattern for app display names

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This script will DELETE Azure AD app registrations!${NC}"
echo -e "${YELLOW}Usage: $0 [true|false] [filter_pattern]${NC}"
echo -e "${YELLOW}  - First argument: dry-run mode (default: true)${NC}"
echo -e "${YELLOW}  - Second argument: optional filter pattern for app names${NC}"
echo ""

# Safety confirmation for non-dry-run mode
if [[ "$dryrun" == "false" ]]; then
    echo -e "${RED}🚨 DESTRUCTIVE OPERATION - This will permanently DELETE app registrations!${NC}"
    echo "Current tenant information:"
    az account show --query '{tenantId: tenantId, name: name}' -o table || {
        echo "Failed to get tenant information. Exiting."
        exit 1
    }
    echo ""
    
    read -p "Type 'DELETE' in ALL CAPS to confirm this destructive operation: " confirm
    if [[ "$confirm" != "DELETE" ]]; then
        echo "Operation cancelled for safety."
        exit 1
    fi
fi

# Login to your Azure account
echo "Logging in to Azure..."
az login || {
    echo "Failed to login to Azure. Exiting."
    exit 1
}

# Set your default subscription
# az account set --subscription "your-subscription-id"

echo "Retrieving app registrations..."

# Get a list of all app registrations with additional details
if [[ -n "$filter_pattern" ]]; then
    echo "Filtering apps by pattern: $filter_pattern"
    appList=$(az ad app list --query "[?contains(displayName, '$filter_pattern')].{appId: appId, displayName: displayName}" -o json)
else
    appList=$(az ad app list --query "[].{appId: appId, displayName: displayName}" -o json)
fi

# Check if any apps were found
appCount=$(echo "$appList" | jq '. | length')
if [[ "$appCount" == "0" ]]; then
    echo "No app registrations found matching the criteria."
    exit 0
fi

echo "Found $appCount app registration(s):"
echo "$appList" | jq -r '.[] | "- \(.displayName) (\(.appId))"'
echo ""

if [[ "$dryrun" == "true" ]]; then
    echo -e "${GREEN}🔍 DRY RUN MODE - No apps will be deleted${NC}"
    echo "The following apps would be deleted:"
    echo "$appList" | jq -r '.[] | "  ❌ \(.displayName) (\(.appId))"'
    echo ""
    echo "To actually delete these apps, run: $0 false"
    exit 0
fi

# Actually delete the apps (non-dry-run mode)
echo -e "${RED}🗑️  Deleting app registrations...${NC}"
deleted_count=0
failed_count=0

for row in $(echo "$appList" | jq -r '.[] | @base64'); do
    _jq() {
        echo "$row" | base64 --decode | jq -r "$@"
    }
    
    appId=$(_jq '.appId')
    displayName=$(_jq '.displayName')
    
    echo "Deleting: $displayName ($appId)"
    
    if az ad app delete --id "$appId" 2>/dev/null; then
        echo -e "  ${GREEN}✅ Successfully deleted${NC}"
        ((deleted_count++))
    else
        echo -e "  ${RED}❌ Failed to delete${NC}"
        ((failed_count++))
    fi
done

echo ""
echo "Summary:"
echo "  Deleted: $deleted_count"
echo "  Failed: $failed_count"
echo "  Total: $appCount"
