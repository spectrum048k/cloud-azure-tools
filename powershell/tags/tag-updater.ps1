
<#
.SYNOPSIS
  Update all resource group tags from a CSV file for all subscriptions in a management group.

.PARAMETER CSVFilePath
  Path to the CSV file containing tag data.
.PARAMETER TenantId
  Azure AD Tenant ID.
.PARAMETER ManagementGroupName
  Name of the management group.
.PARAMETER KeyTag
  The tag key to match between resource group and CSV (e.g. OrgId).
.PARAMETER TagMappings
  Hashtable mapping tag keys to CSV columns (e.g. @{ Country = "Country"; Industry = "Industry" })
.PARAMETER Deploy
  If true, actually update tags. If false, dry-run only.

.EXAMPLE
  .\tag-updater.ps1 -CSVFilePath "organizations-100.csv" -TenantId "<tenant-guid>" -ManagementGroupName "production" -KeyTag "OrgId" -TagMappings @{ Country = "Country"; Industry = "Industry" } -Deploy $true
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$CSVFilePath,
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    [Parameter(Mandatory=$true)]
    [string]$ManagementGroupName,
    [Parameter(Mandatory=$true)]
    [string]$KeyTag,
    [Parameter(Mandatory=$true)]
    [hashtable]$TagMappings,
    [bool]$Deploy = $false
)

Import-Module Az -ErrorAction Stop

if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    Connect-AzAccount -TenantId $TenantId | Out-Null
}

try {
    $subs = Get-AzManagementGroupSubscription -GroupId $ManagementGroupName
} catch {
    Write-Error "Failed to get subscriptions for management group $ManagementGroupName: $_"
    exit 1
}

try {
    $CSVData = Import-Csv -Path $CSVFilePath
} catch {
    Write-Error "Failed to import CSV file $CSVFilePath: $_"
    exit 1
}

$subIndex = 0
foreach ($sub in $subs) {
    $subIndex++
    $percent = [int](($subIndex / $subs.Count) * 100)
    Write-Progress -Activity "Processing subscriptions" -Status "Subscription $subIndex of $($subs.Count)" -PercentComplete $percent
    try {
        Set-AzContext -SubscriptionId $sub.SubscriptionId -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning "Failed to set context for subscription $($sub.SubscriptionId): $_"
        continue
    }
    try {
        $resourceGroups = Get-AzResourceGroup
    } catch {
        Write-Warning "Failed to get resource groups for subscription $($sub.SubscriptionId): $_"
        continue
    }
    foreach ($resourceGroup in $resourceGroups) {
        try {
            $tags = (Get-AzResourceGroup -Name $resourceGroup.ResourceGroupName).Tags
        } catch {
            Write-Warning "Failed to get tags for resource group $($resourceGroup.ResourceGroupName): $_"
            continue
        }
        if ($null -ne $tags -and $tags.ContainsKey($KeyTag)) {
            $matchingRows = $CSVData | Where-Object { $_.$KeyTag -eq $tags[$KeyTag] }
            $count = $matchingRows.Count
            if ($count -eq 0) {
                Write-Host "No matching rows found in CSV data for $KeyTag value $($tags[$KeyTag])" -ForegroundColor Yellow
            } elseif ($count -eq 1) {
                Write-Host "One matching row found in CSV data for $KeyTag value $($tags[$KeyTag])" -ForegroundColor Green
                $currentTagsFlat = ($tags.GetEnumerator() | ForEach-Object { "$($_.Key):$($_.Value)" }) -join ', '
                Write-Host "Subscription $($sub.SubscriptionId) resource group $($resourceGroup.ResourceGroupName), current tags: $currentTagsFlat"
                $row = $matchingRows[0]
                $changed = $false
                foreach ($tagKey in $TagMappings.Keys) {
                    $csvCol = $TagMappings[$tagKey]
                    if ($tags[$tagKey] -ne $row.$csvCol) {
                        Write-Host "  Will update tag '$tagKey' from '$($tags[$tagKey])' to '$($row.$csvCol)'"
                        $tags[$tagKey] = $row.$csvCol
                        $changed = $true
                    }
                }
                if ($changed) {
                    if ($Deploy) {
                        try {
                            $result = Update-AzTag -ResourceId $resourceGroup.ResourceId -Tag $tags -Operation Merge
                            Write-Host "  Tags updated for $($resourceGroup.ResourceGroupName)" -ForegroundColor Cyan
                        } catch {
                            Write-Warning "  Failed to update tags for $($resourceGroup.ResourceGroupName): $_"
                        }
                    } else {
                        Write-Host "  (Dry-run) Would update tags for $($resourceGroup.ResourceGroupName)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "  No tag changes needed for $($resourceGroup.ResourceGroupName)" -ForegroundColor Gray
                }
            } else {
                Write-Warning "$count duplicate rows found in CSV data for $KeyTag value $($tags[$KeyTag])"
            }
        } else {
            Write-Host "Subscription $($sub.SubscriptionId) resource group $($resourceGroup.ResourceGroupName) does not have key tag $KeyTag" -ForegroundColor Gray
        }
    }
}
