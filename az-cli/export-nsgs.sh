#!/bin/bash

# Exit on errors, undefined variables, and pipe failures
set -euo pipefail

#
# export NSGs rules to JSON files
#
management_group_id="${1:-test}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting NSG export for management group: $management_group_id${NC}"

# Login and validate connection
echo "Logging in to Azure..."
if ! az login; then
    echo -e "${RED}❌ Failed to login to Azure${NC}"
    exit 1
fi

# Validate management group exists
echo "Validating management group..."
if ! az account management-group show --name "$management_group_id" &>/dev/null; then
    echo -e "${RED}❌ Management group '$management_group_id' not found or not accessible${NC}"
    exit 1
fi

# get a list of all subscriptions in the management group
echo "Retrieving subscriptions from management group..."
if ! subscription_list=$(az account management-group subscription show-sub-under-mg --name "$management_group_id" --query "[].name" --output tsv); then
    echo -e "${RED}❌ Failed to retrieve subscriptions from management group${NC}"
    exit 1
fi

if [[ -z "$subscription_list" ]]; then
    echo -e "${YELLOW}⚠️  No subscriptions found in management group '$management_group_id'${NC}"
    exit 0
fi

echo -e "${GREEN}Found subscriptions:${NC} $subscription_list"

# Statistics tracking
total_subscriptions=0
total_resource_groups=0
total_nsgs=0
total_files_created=0
failed_operations=0

for subscription_id in $subscription_list
do
    echo -e "\n${GREEN}📋 Processing Subscription:${NC} $subscription_id"
    ((total_subscriptions++))

    # Set the current subscription
    if ! az account set --subscription "$subscription_id"; then
        echo -e "${RED}❌ Failed to set subscription $subscription_id${NC}"
        ((failed_operations++))
        continue
    fi

    # Get resource groups for this subscription
    if ! resource_group_list=$(az group list --subscription "$subscription_id" --query "[].name" --output tsv); then
        echo -e "${RED}❌ Failed to get resource groups for subscription $subscription_id${NC}"
        ((failed_operations++))
        continue
    fi

    if [[ -z "$resource_group_list" ]]; then
        echo -e "${YELLOW}  ⚠️  No resource groups found in subscription $subscription_id${NC}"
        continue
    fi

    echo -e "  ${GREEN}Resource groups:${NC} $resource_group_list"

    for resource_group_name in $resource_group_list
    do
        echo -e "\n  📁 Processing Resource Group: $resource_group_name"
        ((total_resource_groups++))

        # Get NSGs in this resource group
        if ! nsg_list=$(az network nsg list -g "$resource_group_name" --query [].name -o tsv 2>/dev/null); then
            echo -e "${RED}    ❌ Failed to get NSGs for resource group $resource_group_name${NC}"
            ((failed_operations++))
            continue
        fi

        if [[ -z "$nsg_list" ]]; then
            echo "    ℹ️  No NSGs found in resource group $resource_group_name"
            continue
        fi

        echo -e "    ${GREEN}NSGs found:${NC} $nsg_list"

        # loop through all NSGs in the resource group
        for nsg_name in $nsg_list
        do
            echo -e "\n    🔐 Processing NSG: $nsg_name"
            ((total_nsgs++))
            
            filename="$subscription_id:$resource_group_name:$nsg_name.json"
            echo "      📄 Output file: $filename"

            # export NSG rules to a variable with error handling
            if rules=$(az network nsg rule list --nsg-name "$nsg_name" --resource-group "$resource_group_name" --output json 2>/dev/null); then
                # save NSG rules to a file
                if echo "$rules" > "$filename"; then
                    echo -e "      ${GREEN}✅ Successfully exported NSG rules${NC}"
                    ((total_files_created++))
                    
                    # Optionally print rules to screen (commented out to reduce noise)
                    # echo "$rules"
                else
                    echo -e "${RED}      ❌ Failed to write rules to file $filename${NC}"
                    ((failed_operations++))
                fi
            else
                echo -e "${RED}      ❌ Failed to export NSG rules for $nsg_name${NC}"
                ((failed_operations++))
            fi
        done
    done
done

# Print summary
echo -e "\n${GREEN}🎯 Export Summary:${NC}"
echo "  📊 Total subscriptions processed: $total_subscriptions"
echo "  📁 Total resource groups processed: $total_resource_groups"
echo "  🔐 Total NSGs processed: $total_nsgs"
echo "  📄 Total files created: $total_files_created"
if [[ $failed_operations -gt 0 ]]; then
    echo -e "  ${RED}❌ Failed operations: $failed_operations${NC}"
else
    echo -e "  ${GREEN}✅ All operations completed successfully${NC}"
fi