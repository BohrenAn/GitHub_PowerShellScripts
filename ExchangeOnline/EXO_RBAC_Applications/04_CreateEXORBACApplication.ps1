###############################################################################
# Create Exchange Exchange RBAC for Applications
# V0.1 03.06.2026 - Initial Version - Andres Bohren
# V0.2 09.09.2026 - Added Group Scope and Management Scope handling - Andres Bohren
###############################################################################
# Reqired Modules:
# - ExchangeOnlineManagement
# Required Permissions:
# - Exchange Administrator (Exchange Online)
###############################################################################

PARAM (
    [Parameter(Mandatory=$true)][string]$AppID,
    [Parameter(Mandatory=$true)][Array]$AppPermissions,
    [Parameter(Mandatory=$true)][string]$GroupObjectID
)


# Check if Verbose was specified
If ($PSBoundParameters.ContainsKey('Verbose')) 
{
    Write-Host "-Verbose was specified"
}


# Check Exchange Online Connection
$Connection = Get-ConnectionInformation -ErrorAction SilentlyContinue
if ($Connection) {
    Write-Host "Already connected to Exchange Online"
} else {
    Connect-ExchangeOnline -Showbanner:$false
}

# Get Service Principal for the specified AppID
$ServicePrincipal = Get-ServicePrincipal -AppId $AppID -ErrorAction SilentlyContinue
If ($Null -eq $ServicePrincipal) {
    Write-Host "Service Principal not found" -ForegroundColor Red
    # Handle the case where the service principal is not found
    Exit
} else {
    Write-Host "Service Principal found" -ForegroundColor Green

    Foreach ($Permission in $AppPermissions)
    {
        Write-Host "Assigning Permission: $Permission / Group: $GroupObjectID / App: $AppID" -ForegroundColor Cyan

        # With Group Scope
        # New-ManagementRoleAssignment -App $ServicePrincipal.ObjectId -Role "Application $Permission" -RecipientGroupScope $GroupObjectID

        # With ManagementScope
        # New-ManagementRoleAssignment -App $ServiceId -Role "Application Mail.Read" -CustomResourceScope $ManagementScope
    }
}