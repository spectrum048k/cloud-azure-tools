#!/bin/bash

# Exit on errors, undefined variables, and pipe failures
set -euo pipefail

management_group_name_source="${1:-}"
management_group_name_target="${2:-}"
dryrun="${3:-false}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ -z "$management_group_name_source" || -z "$management_group_name_target" ]]; then
    echo -e "${RED}❌ Error: Missing required parameters${NC}"
    echo -e "${YELLOW}Usage: $0 <source_management_group> <target_management_group> [dryrun]${NC}"
    echo "  - source_management_group: Name of the source management group"
    echo "  - target_management_group: Name of the target management group"
    echo "  - dryrun: Optional. Set to 'true' for dry-run mode (default: false)"
    exit 1
fi

echo -e "${GREEN}🔄 Moving subscriptions from '$management_group_name_source' to '$management_group_name_target'${NC}"
if [[ "$dryrun" == "true" ]]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No actual changes will be made${NC}"
fi

# Validate Azure CLI is available and user is logged in
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found. Please install Azure CLI first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! az account show &>/dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure. Attempting login...${NC}"
    if ! az login; then
        echo -e "${RED}❌ Failed to login to Azure${NC}"
        exit 1
    fi
fi

# Validate source management group exists
echo "🔍 Validating source management group..."
if ! az account management-group show --name "$management_group_name_source" &>/dev/null; then
    echo -e "${RED}❌ Source management group '$management_group_name_source' not found or not accessible${NC}"
    exit 1
fi

# Validate target management group exists
echo "🔍 Validating target management group..."
if ! az account management-group show --name "$management_group_name_target" &>/dev/null; then
    echo -e "${RED}❌ Target management group '$management_group_name_target' not found or not accessible${NC}"
    exit 1
fi

# Retrieve a list of subscriptions from the source management group
echo "📋 Retrieving subscriptions from source management group..."
if ! subscriptions=$(az account management-group subscription show-sub-under-mg -n "$management_group_name_source" -o json); then
    echo -e "${RED}❌ Failed to retrieve subscriptions from source management group${NC}"
    exit 1
fi

# Count the number of subscriptions
subscription_count=$(echo "$subscriptions" | jq '. | length')

if [[ "$subscription_count" == "0" ]]; then
    echo -e "${YELLOW}⚠️  No subscriptions found in source management group${NC}"
    exit 0
fi

echo -e "${GREEN}📊 Found $subscription_count subscription(s) in source management group${NC}"

# Statistics tracking
moved_count=0
skipped_count=0
failed_count=0

for row in $(echo "$subscriptions" | jq -r '.[] | @base64'); do
    _jq() {
        echo "$row" | base64 --decode | jq -r "$@"
    }

    subscription_id=$(_jq '.name')
    subscription_name=$(_jq '.displayName')
    state=$(_jq '.state')

    echo -e "\n📋 Processing: $subscription_name ($subscription_id) - State: $state"

    # if the state is not "Active", then we don't want to move it
    if [[ "$state" != "Active" ]]; then
        echo -e "${YELLOW}  ⏭️  Skipping: Subscription is not in Active state${NC}"
        ((skipped_count++))
        continue
    fi

    if [[ "$dryrun" == "true" ]]; then
        echo -e "${YELLOW}  🔍 DRY RUN: Would move $state subscription \"$subscription_name\" $subscription_id to group $management_group_name_target${NC}"
        ((moved_count++))
    else
        echo -e "${GREEN}  🔄 Moving $state subscription \"$subscription_name\" $subscription_id to group $management_group_name_target${NC}"

        # move the subscription to the target management group
        if az account management-group subscription add -n "$management_group_name_target" --subscription "$subscription_id" 2>/dev/null; then
            echo -e "${GREEN}    ✅ Successfully moved subscription${NC}"
            ((moved_count++))
        else
            echo -e "${RED}    ❌ Failed to move subscription${NC}"
            ((failed_count++))
        fi
    fi
done

# Print summary
echo -e "\n${GREEN}🎯 Operation Summary:${NC}"
echo "  📊 Total subscriptions found: $subscription_count"
if [[ "$dryrun" == "true" ]]; then
    echo "  🔍 Subscriptions that would be moved: $moved_count"
else
    echo -e "  ${GREEN}✅ Successfully moved: $moved_count${NC}"
    if [[ $failed_count -gt 0 ]]; then
        echo -e "  ${RED}❌ Failed to move: $failed_count${NC}"
    fi
fi
echo -e "  ${YELLOW}⏭️  Skipped (inactive): $skipped_count${NC}"

if [[ "$dryrun" == "true" && $moved_count -gt 0 ]]; then
    echo -e "\n${YELLOW}To actually perform the move operation, run:${NC}"
    echo "  $0 \"$management_group_name_source\" \"$management_group_name_target\" false"
fi