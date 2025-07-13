
<#
.SYNOPSIS
  Export all resource group tags from all subscriptions in a management group to a CSV file.

.PARAMETER FileName
  Output CSV file path.
.PARAMETER ManagementGroupName
  Name of the management group.
.PARAMETER TenantId
  Azure AD Tenant ID.

.EXAMPLE
  .\tag-exporter.ps1 -FileName "rg-tags.csv" -ManagementGroupName "production" -TenantId "<tenant-guid>"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$FileName,
    [Parameter(Mandatory=$true)]
    [string]$ManagementGroupName,
    [Parameter(Mandatory=$true)]
    [string]$TenantId
)

Import-Module Az -ErrorAction Stop


if (-not (Get-AzContext)) {
    Write-Host "Connecting to Azure..." -ForegroundColor Yellow
    try {
        Connect-AzAccount -TenantId $TenantId | Out-Null
    } catch {
        Write-Error "Failed to authenticate to Azure for tenant $TenantId. $_"
        exit 1
    }
}

try {
    $subs = Get-AzManagementGroupSubscription -GroupId $ManagementGroupName
} catch {
    Write-Error "Failed to get subscriptions for management group ${ManagementGroupName}: $_"
    exit 1
}

$resourceGroupTags = @()
$subIndex = 0
foreach ($sub in $subs) {
    $subIndex++
    $percent = [int](($subIndex / $subs.Count) * 100)
    Write-Progress -Activity "Processing subscriptions" -Status "Subscription $subIndex of $($subs.Count)" -PercentComplete $percent
    if (-not $sub.Id) {
        Write-Error "Missing Id for subscription (DisplayName: $($sub.DisplayName)). Stopping script."
        break
    }
    $subscriptionId = ($sub.Id -split '/')[-1]
    try {
        Set-AzContext -SubscriptionId $subscriptionId -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "Failed to set context for subscription ${subscriptionId}: $_"
        break
    }
    try {
        $resourceGroups = Get-AzResourceGroup
    } catch {
        Write-Error "Failed to get resource groups for subscription ${subscriptionId}: $_"
        break
    }
    foreach ($resourceGroup in $resourceGroups) {
        try {
            $tags = (Get-AzResourceGroup -Name $resourceGroup.ResourceGroupName).Tags
        } catch {
            Write-Warning "Failed to get tags for resource group $($resourceGroup.ResourceGroupName): $_"
            continue
        }
        if ($null -ne $tags -and $tags.Count -gt 0) {
            foreach ($tagKey in $tags.Keys) {
                $resourceGroupTags += [PSCustomObject]@{
                    Subscription = $subscriptionId
                    ResourceGroupName = $resourceGroup.ResourceGroupName
                    TagName = $tagKey
                    TagValue = $tags[$tagKey]
                }
            }
        }
    }
}

if ($resourceGroupTags.Count -eq 0) {
    Write-Host "No tags found to export." -ForegroundColor Yellow
} else {
    $resourceGroupTags | Export-Csv -Path $FileName -NoTypeInformation
}
