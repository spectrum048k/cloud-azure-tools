#!/bin/bash

management_group_name_source="$1"
management_group_name_target="$2"
dryrun="${3:-false}"

if [[ -z "$management_group_name_source" || -z "$management_group_name_target" ]]; then
    echo "Please provide the name of the source and target management groups as the first and second arguments."
    exit 1
fi

# Retrieve a list of subscriptions from the source management group
subscriptions=$(az account management-group subscription show-sub-under-mg -n "$management_group_name_source" -o json)

# Count the number of subscriptions
subscription_count=$(echo "$subscriptions" | jq '. | length')

echo "Number of subscriptions: $subscription_count"

for row in $(echo "$subscriptions" | jq -r '.[] | @base64'); do
    _jq() {
        echo "$row" | base64 --decode | jq -r "$@"
    }

    subscription_id=$(_jq '.name')
    subscription_name=$(_jq '.displayName')
    state=$(_jq '.state')

    # if the state is not "Active", then we don't want to move it
    if [[ "$state" != "Active" ]]; then
        echo "Skipping subscription $subscription_name because it is not in the Active state."
        continue
    fi

    if [[ "$dryrun" == "true" ]]; then
        echo "Dry run: $state subscription \"$subscription_name\" $subscription_id to group $management_group_name_target."
    else
      echo "Moving $state subscription \"$subscription_name\" $subscription_id to group $management_group_name_target."

      # move the subscription to the target management group
      az account management-group subscription add -n "$management_group_name_target" --subscription "$subscription_id"
    fi
done