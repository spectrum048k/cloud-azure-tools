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
      [string]$KeyTag,
      [bool]$Deploy = $false
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
          Write-Output "No matching rows found in CSV data for $($KeyTag) value $($tags[$KeyTag])"
        } elseif ($count -eq 1) {
          Write-Output "One matching row found in CSV data for $($KeyTag) value $($tags[$KeyTag])"

          $currentTagsFlat = Get-Flatten-HashTable($tags)
          Write-Output "Subscription $($sub.DisplayName) resource group $($resourceGroup.ResourceGroupName), current tags: $($currentTagsFlat)"

          Get-CheckTags -tags $tags -data $matchingRows[0]
          
          if ($Deploy) {
            $result = Update-AzTag -ResourceId $resourceGroup.ResourceId -Tag $tags -Operation Merge

            if (-not $?) {
              Write-Output $result
            }
          }
        } else {
          $errmsg = "$($count) duplicate rows found in CSV data for $($KeyTag) value $($tags[$KeyTag])"
          throw $errmsg
        }
      }
      else {
        Write-Output "Subscription $($sub.DisplayName) resource group $($resourceGroup.ResourceGroupName) does not have key tag $($KeyTag)"
      }
    }
  }
}


function Get-CheckTags {
  param (
      $tags,
      [object]$data
  )

  $changes = @()
  
  Set-Tag -tags $tags -keyToCheck "Country" -valueToCheck $data.Country
  
  return $tags
}

function Set-Tag {
  param (
    $tags,
    [string]$keyToCheck,
    [string]$valueToCheck
  )

  if ($tags.ContainsKey($keyToCheck) -and $tags[$keyToCheck] -eq $valueToCheck) {
    
  }
  else {
    $tags[$keyToCheck] = $valueToCheck
  }

}

function Get-Flatten-HashTable {
  param (
      [hashtable]$HashTable
  )

  # Convert the hashtable to a single line string
  $flatString = ($HashTable.GetEnumerator() | ForEach-Object { "$($_.Key):$($_.Value)" }) -join ', '

  return $flatString
}

$data = Import-CSVData "organizations-100.csv"

Update-AllResourceGroupTags -ManagementGroupName `
  "production" -TenantId "de62f6b5-50bb-4689-8981-140efd114aa2" `
  -CSVData $data `
  -KeyTag "OrgId"

# Now $data contains the data from your CSV file
# You can access the data using properties of the objects in the array
# foreach ($row in $data) {
#   Write-Output "OrgId: $($row.'Organization Id'), Name: $($row.Name), Industry: $($row.Industry), Country: $($row.Country)"
# }
