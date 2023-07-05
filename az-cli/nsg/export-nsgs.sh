#!/bin/bash

#
# export NSGs rules to JSON files
#
management_group_id="${1:-test}"

echo $management_group_id

az login

# get a list of all subscriptions in the management group
subscription_list=$(az account management-group subscription show-sub-under-mg --name $management_group_id --query "[].name" --output tsv)

echo "Subscriptions list:" $subscription_list

for subscription_id in $subscription_list
do
    echo "Subscription:" $subscription_id

    # Set the current subscription
    az account set --subscription "$subscription_id"

    # Perform actions on each subscription
    resource_group_list=$(az group list --subscription $subscription_id --query "[].name" --output tsv)
    echo "Resource group list" $resource_group_list

    for resource_group_name in $resource_group_list
    do
      echo "Resource group:" $resource_group_name

      nsg_list=$(az network nsg list -g $resource_group_name --query [].name -o tsv)
      echo "NSG list:" $nsg_list

      # loop through all NSGs in the subscription
      for nsg_name in $nsg_list
      do
        filename="$nsg_name.json"
        echo "filename:" $filename

        # export NSG rules to a variable
        rules=$(az network nsg rule list --nsg-name $nsg_name --resource-group $resource_group_name --output json)

        # save NSG rules to a file
        echo $rules > $filename
        
        # print NSG rules to the screen
        echo $rules
        done
    done
done