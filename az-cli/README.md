# Azure CLI Scripts

This directory contains Azure CLI scripts for common Azure management tasks. All scripts include comprehensive error handling, safety mechanisms, and user-friendly feedback.

## 📁 Directory Structure

```
az-cli/
├── export-nsgs.sh          # Export Network Security Group rules
├── move-subs.sh            # Move subscriptions between management groups
├── azuread/
│   ├── del-ad-apps.ps1     # Delete Azure AD apps (PowerShell)
│   └── del-ad-apps.sh      # Delete Azure AD apps (Bash)
└── README.md               # This file
```

## 🛡️ Safety Features

All scripts include the following safety mechanisms:

- **Error handling**: Scripts exit on errors with clear error messages
- **Validation**: Resource existence validation before operations
- **Color-coded output**: Green (success), Yellow (warning), Red (error)
- **Progress tracking**: Detailed progress indicators and statistics
- **Safe defaults**: Destructive operations default to dry-run mode

## 📋 Prerequisites

- **Azure CLI**: Install from [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **jq**: JSON processor (required for `move-subs.sh`)
  ```bash
  # macOS
  brew install jq
  
  # Ubuntu/Debian
  sudo apt-get install jq
  
  # RHEL/CentOS
  sudo yum install jq
  ```
- **Azure Login**: Must be logged in with appropriate permissions

## 🔐 Required Permissions

### For `export-nsgs.sh`:
- **Reader** role on target management groups and subscriptions
- **Network Contributor** or **Reader** role on resource groups containing NSGs

### For `move-subs.sh`:
- **Management Group Contributor** role on both source and target management groups
- **Owner** or **User Access Administrator** role on subscriptions being moved

### For `del-ad-apps.*`:
- **Application Administrator** or **Cloud Application Administrator** role in Azure AD
- **Global Administrator** role (for some app types)

---

## 📄 Scripts Documentation

### 1. `export-nsgs.sh` - Export Network Security Group Rules

Exports NSG rules from all subscriptions in a management group to JSON files.

#### Usage
```bash
./export-nsgs.sh [management_group_id]
```

#### Parameters
- `management_group_id` (optional): Target management group ID (default: "test")

#### Examples
```bash
# Export NSGs from default management group
./export-nsgs.sh

# Export NSGs from specific management group
./export-nsgs.sh production

# Export NSGs from development environment
./export-nsgs.sh dev-environment
```

#### Output Files
Creates JSON files with naming pattern: `{subscription_id}:{resource_group}:{nsg_name}.json`

Example: `64521a0a-82fb-41de-9a02-7409302af74d:rg-web-prod:nsg-web-frontend.json`

#### Features
- ✅ Validates management group existence
- ✅ Processes all subscriptions in management group
- ✅ Handles empty resource groups gracefully
- ✅ Comprehensive error handling per operation
- ✅ Detailed progress reporting and statistics

---

### 2. `move-subs.sh` - Move Subscriptions Between Management Groups

Moves active subscriptions from one management group to another with dry-run capability.

#### Usage
```bash
./move-subs.sh <source_mg> <target_mg> [dryrun]
```

#### Parameters
- `source_mg` (required): Source management group name
- `target_mg` (required): Target management group name  
- `dryrun` (optional): Set to "true" for dry-run mode (default: false)

#### Examples
```bash
# Dry-run: See what would be moved
./move-subs.sh dev-mg prod-mg true

# Actually move subscriptions (requires confirmation)
./move-subs.sh dev-mg prod-mg false

# Move with explicit dry-run
./move-subs.sh old-structure new-structure true
```

#### Features
- ✅ **Dry-run mode**: Safe testing without actual changes
- ✅ **Smart filtering**: Only moves "Active" subscriptions
- ✅ **Validation**: Checks both source and target management groups exist
- ✅ **Detailed reporting**: Shows moved, skipped, and failed operations
- ✅ **Azure CLI validation**: Ensures user is logged in

---

### 3. `del-ad-apps.sh` / `del-ad-apps.ps1` - Delete Azure AD Applications

⚠️ **DESTRUCTIVE OPERATION** - Deletes Azure AD app registrations with comprehensive safety features.

#### Usage

**Bash:**
```bash
./azuread/del-ad-apps.sh [dry_run] [filter_pattern]
```

**PowerShell:**
```powershell
.\azuread\del-ad-apps.ps1 [-DryRun true|false] [-FilterPattern "pattern"]
```

#### Parameters
- `dry_run` / `DryRun`: Dry-run mode (default: **true** for safety)
- `filter_pattern` / `FilterPattern`: Optional filter for app display names

#### Examples

**Safe exploration (dry-run mode):**
```bash
# Show all apps that would be deleted (safe)
./azuread/del-ad-apps.sh

# Show apps matching pattern (safe)
./azuread/del-ad-apps.sh true "test-"

# Show apps containing "dev" (safe)
./azuread/del-ad-apps.sh true "dev"
```

**Actual deletion (requires confirmation):**
```bash
# Delete specific app (requires typing "DELETE")
./azuread/del-ad-apps.sh false "sp-tf-deploy"

# Delete all test apps (requires typing "DELETE")  
./azuread/del-ad-apps.sh false "test-"
```

#### 🚨 Safety Features
- ✅ **Defaults to dry-run**: No accidental deletions
- ✅ **Confirmation required**: Must type "DELETE" in all caps
- ✅ **Tenant validation**: Shows current tenant before deletion
- ✅ **Filtering support**: Target specific apps instead of mass deletion
- ✅ **Detailed preview**: Shows exactly what will be deleted
- ✅ **Comprehensive reporting**: Success/failure statistics

#### ⚠️ **IMPORTANT SAFETY NOTES**
- **Always test with dry-run first**: `./azuread/del-ad-apps.sh true`
- **Use filtering**: Target specific apps rather than deleting all
- **Verify tenant**: Ensure you're in the correct Azure AD tenant
- **Backup consideration**: App registrations cannot be recovered once deleted
- **Production warning**: Never run without filtering in production environments

---

## 🎯 Best Practices

### 1. **Always Test First**
```bash
# Run in dry-run mode first
./export-nsgs.sh test-mg
./move-subs.sh source target true
./azuread/del-ad-apps.sh true "filter"
```

### 2. **Use Specific Filters**
```bash
# Good: Target specific resources
./azuread/del-ad-apps.sh false "test-app-123"

# Dangerous: No filtering
./azuread/del-ad-apps.sh false
```

### 3. **Verify Permissions**
```bash
# Check current login and permissions
az account show
az account list-locations --query "[].name" -o table
```

### 4. **Monitor Output**
- Watch for error messages (🔴 red text)
- Review summary statistics
- Check created files for expected content

## 🚨 Troubleshooting

### Common Issues

#### 1. **"Management group not found"**
```bash
# List available management groups
az account management-group list --query "[].{name:name, displayName:displayName}" -o table

# Check permissions
az account show
```

#### 2. **"Failed to login to Azure"**
```bash
# Re-login to Azure
az login

# Login to specific tenant
az login --tenant TENANT_ID
```

#### 3. **"No subscriptions found"**
```bash
# Check if management group has subscriptions
az account management-group subscription show-sub-under-mg --name MG_NAME
```

#### 4. **Permission errors**
```bash
# Check current user roles
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Script-Specific Troubleshooting

#### `export-nsgs.sh`
- **Empty output**: Management group may have no NSGs
- **Permission errors**: Ensure Reader access to target resources
- **Large output**: Consider filtering by specific resource groups

#### `move-subs.sh`
- **Move failures**: Check Management Group Contributor permissions
- **Subscription not found**: Verify subscription is in source management group
- **jq errors**: Ensure jq is installed (`brew install jq`)

#### `del-ad-apps.*`
- **App not found**: Use `az ad app list` to verify app exists
- **Permission denied**: Ensure Application Administrator role
- **Filter not working**: Check app display names with `az ad app list --query "[].displayName"`

## 📊 Output Examples

### Successful `export-nsgs.sh` run:
```
🎯 Export Summary:
  📊 Total subscriptions processed: 2
  📁 Total resource groups processed: 8
  🔐 Total NSGs processed: 5
  📄 Total files created: 5
  ✅ All operations completed successfully
```

### Successful `move-subs.sh` run:
```
🎯 Operation Summary:
  📊 Total subscriptions found: 3
  ✅ Successfully moved: 2
  ⏭️  Skipped (inactive): 1
```

### Safe `del-ad-apps.sh` run:
```
🔍 DRY RUN MODE - No apps will be deleted
The following apps would be deleted:
  ❌ test-app-123 (app-id-123)
  
To actually delete these apps, run: ./azuread/del-ad-apps.sh false
```

## 🔗 Related Documentation

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure Management Groups](https://docs.microsoft.com/en-us/azure/governance/management-groups/)
- [Azure AD App Registrations](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)