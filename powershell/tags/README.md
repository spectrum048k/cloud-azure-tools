# PowerShell Tag Management Scripts

This directory contains scripts for exporting and updating Azure Resource Group tags across all subscriptions in a management group using PowerShell and CSV files.

## Contents

- `tag-exporter.ps1` — Export all resource group tags to a CSV file
- `tag-updater.ps1` — Update resource group tags from a CSV file
- `organizations-100.csv` — Example CSV data for tag updates

---

## Prerequisites

- PowerShell 7+ (recommended)
- Azure PowerShell module (`Az`)
- Sufficient Azure permissions to read and update resource groups and tags
- Access to the target Azure tenant and management group

Install the Az module if needed:
```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

---

## Usage

### 1. Export Resource Group Tags

Exports all tags from all resource groups in all subscriptions under a management group to a CSV file.

```powershell
# Authenticate first (if not already authenticated)
Connect-AzAccount -TenantId "<your-tenant-id>"

# Export tags
./tag-exporter.ps1 -FileName "rg-tags.csv" -ManagementGroupName "<mg-name>" -TenantId "<your-tenant-id>"
```

- `FileName`: Output CSV file path
- `ManagementGroupName`: Name of the management group
- `TenantId`: Azure AD tenant ID

### 2. Update Resource Group Tags from CSV

Updates tags for all resource groups in all subscriptions under a management group, using a CSV file as the source of truth. Supports dry-run mode and configurable tag mapping.

```powershell
# Example tag mapping: update Country and Industry tags from CSV columns
$tagMappings = @{ Country = "Country"; Industry = "Industry" }

./tag-updater.ps1 -CSVFilePath "organizations-100.csv" -TenantId "<your-tenant-id>" -ManagementGroupName "<mg-name>" -KeyTag "OrgId" -TagMappings $tagMappings -Deploy $false
```

- `CSVFilePath`: Path to the CSV file
- `TenantId`: Azure AD tenant ID
- `ManagementGroupName`: Name of the management group
- `KeyTag`: Tag key to match between resource group and CSV (e.g. `OrgId`)
- `TagMappings`: Hashtable mapping tag keys to CSV columns
- `Deploy`: If `$true`, actually update tags; if `$false`, dry-run only

---

## Example CSV Structure

```
OrgId,Name,Country,Industry
12345,Contoso,USA,Technology
67890,Fabrikam,UK,Finance
...
```

---

## Best Practices

- Always run in dry-run mode (`-Deploy $false`) first to preview changes
- Ensure your CSV file has a unique key column (e.g. `OrgId`) for matching
- Use clear and consistent tag names and values
- Review script output for errors or warnings

---

## Troubleshooting

- **Authentication errors**: Run `Connect-AzAccount -TenantId <your-tenant-id>`
- **No tags found**: Ensure resource groups have tags and you have access
- **Parameter errors**: Check that all required parameters are provided and correct
- **CSV issues**: Ensure the CSV file exists and has the expected columns

---

## References

- [Azure PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/azure/)
- [Azure Resource Tagging Best Practices](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources)
