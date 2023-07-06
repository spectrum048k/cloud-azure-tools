# Login to your Azure account
az login

# Set your default subscription
# az account set --subscription "your-subscription-id"

# Get a list of all app registrations in your Azure AD tenant
$appRegistrations = $(az ad app list --query "[].appId" -o tsv)

# Loop through each app registration and delete it
foreach ($appId in $appRegistrations) {
    Write-Host $appId
    az ad app delete --id $appId
}
