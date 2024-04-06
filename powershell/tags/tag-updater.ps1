function Import-CSVData {
  param (
      [string]$FilePath,
      [string]$TenantId
  )

  if (-not (Test-Path $FilePath)) {
      Write-Error "File '$FilePath' not found."
      return
  }

  $data = Import-Csv -Path $FilePath

  return $data
}

function Update-AllResourceGroupTags {
  param (
      [string]$ManagementGroupName,
      [string]$TenantId,
      [object]$CSVData,
      [string]$KeyTag
  )

  # Install the Azure PowerShell module if you haven't already
  # Install-Module -Name Az -AllowClobber -Scope CurrentUser

  Import-Module Az -ErrorAction Stop

  # Connect to Azure (if not already connected)
  if (-not (Get-AzContext)) {
      Write-Output "Connecting to Azure.."
      Connect-AzAccount -TenantId $TenantId
  }

  # Get all subscriptions within the management group
  $subs = Get-AzManagementGroupSubscription -GroupId $ManagementGroupName

  # Initialize an array to store resource group tags
  $tagChanges = @()

  foreach ($sub in $subs) {
      # Set the current subscription context
      Set-AzContext -SubscriptionId $sub.DisplayName

      # Get information about the current subscription
      $subscription = Get-AzSubscription

      # Get all resource groups within the subscription
      $resourceGroups = Get-AzResourceGroup

      # Iterate through each resource group
      foreach ($resourceGroup in $resourceGroups) {
        $tags = (Get-AzResourceGroup -Name $resourceGroup.ResourceGroupName).Tags

        if ($null -ne $tags -and $tags.ContainsKey($KeyTag)) {
          # lookup csv version of tag, filter the rows where the specified field matches the specified value
          $matchingRows = $CSVData.Where({ $_.$KeyTag -eq $tags[$KeyTag] })

          $count = $matchingRows.Count

          if ($count -eq 0) {
            Write-Output "No matching rows found in CSV data for $($KeyTag) value $tags[$KeyTag]"
          } elseif ($count -eq 1) {
            Write-Debug "One matching rows found in CSV data for $($KeyTag) value $tags[$KeyTag]"
          } else {
            $errmsg = "$($count) duplicate rows found in CSV data for $($KeyTag) value $($tags[$KeyTag])"
            throw $errmsg
          }

          Write-Output "Subscription $($sub.DisplayName) resource group $($resourceGroup.ResourceGroupName)"
          $currentTags = Flatten-HashTable($tags)
          Write-Output "Current tags $($currentTags)"

          # $newTags = @{
          #   "Environment" = "Production"
          #   "Owner" = "John Doe"
          #   "Department" = "IT"
          # }

          # Update-ResourceGroupTag -ResourceGroup $resourceGroup -Tags $tags
        }
        else {
          Write-Output "Subscription $($sub.DisplayName) resource group $($resourceGroup.ResourceGroupName) does not have key tag $($KeyTag)"
        }
      }
  }
}

function Flatten-HashTable {
  param (
      [hashtable]$HashTable
  )

  # Convert the hashtable to a single line string
  $flatString = ($HashTable.GetEnumerator() | ForEach-Object { "$($_.Key):$($_.Value)" }) -join ', '

  # Return the flattened string
  return $flatString
}

$data = Import-CSVData "organizations-100.csv"

Update-AllResourceGroupTags -ManagementGroupName `
"production" -TenantId "" `
-CSVData $data `
-KeyTag "OrgId"

# Now $data contains the data from your CSV file
# You can access the data using properties of the objects in the array
# foreach ($row in $data) {
#   Write-Output "OrgId: $($row.'Organization Id'), Name: $($row.Name), Industry: $($row.Industry), Country: $($row.Country)"
# }
