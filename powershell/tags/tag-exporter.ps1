function Export-ResourceGroupTagsToCsv {
  param (
    [string]$FileName,
    [string]$ManagementGroupName,
    [string]$TenantId
)

  Import-Module Az -ErrorAction Stop

  # Connect to Azure (if not already connected)
  if (-not (Get-AzContext)) {
      Write-Output "Connecting to Azure.."
      Connect-AzAccount -TenantId $TenantId
  }

  # Get all subscriptions within the management group
  $subs = Get-AzManagementGroupSubscription -GroupId $ManagementGroupName

  # Initialize an array to store resource group tags
  $resourceGroupTags = @()

  # Iterate through each subscription
  foreach ($sub in $subs) {
    # Set the current subscription context
    Set-AzContext -SubscriptionId $sub.DisplayName

    # Get all resource groups within the subscription
    $resourceGroups = Get-AzResourceGroup

    # Iterate through each resource group
    foreach ($resourceGroup in $resourceGroups) {
        # Get the tags of the current resource group
        $tags = (Get-AzResourceGroup -Name $resourceGroup.ResourceGroupName).Tags

        if ($null -ne $tags -and $tags.Count -gt 0) {
          # Iterate through each tag in the hash table
          foreach ($tagKey in $tags.Keys) {
            # Add a row for each tag
            $resourceGroupTags += [PSCustomObject]@{
                Subscription = $sub.DisplayName
                ResourceGroupName = $resourceGroup.ResourceGroupName
                TagName = $tagKey
                TagValue = $tags[$tagKey]
            }
          }
        }
    }
  }

  # Export the resource group tags to a CSV file
  $resourceGroupTags | Export-Csv -Path $FileName -NoTypeInformation
}

$fileName = "rg-tags.csv"
$managementGroupName = "production"
Export-ResourceGroupTagsToCsv -FileName $fileName -ManagementGroupName $managementGroupName `
-TenantId ""
