###############################################################################
# Create Exchange Exchange RBAC for Applications
# V0.1 xx.xx.2026 - Initial Version - Andres Bohren
###############################################################################
# Reqired Modules:
# - ExchangeOnlineManagement
# - Microsoft.Graph
# Required Permissions:
# - Exchange Administrator (Exchange Online)
# - Application.Read.All (Microsoft Graph)
###############################################################################

PARAM (
    [Parameter(Mandatory=$true)][string]$AppID,
    [Parameter(Mandatory=$true)][string]$AppPermission,
    [Parameter(Mandatory=$true)][string]$GroupObjectID
)

