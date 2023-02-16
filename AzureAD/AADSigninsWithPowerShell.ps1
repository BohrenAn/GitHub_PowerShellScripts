###############################################################################
# Query AzureAD Signins with Powershell
# 2023-01-26 - Initial Version - Andres Bohren
###############################################################################

###############################################################################
# Graph Explorer
###############################################################################
#Go to https://aka.ms/ge
https://graph.microsoft.com/v1.0/auditLogs/signIns
https://graph.microsoft.com/v1.0/auditLogs/signIns?&$filter=startsWith(userPrincipalName,'a.bohren@icewolf.ch')


###############################################################################
# Microsoft Graph permissions reference
# https://learn.microsoft.com/en-us/graph/permissions-reference
###############################################################################

###############################################################################
# Use query parameters to customize responses
# https://docs.microsoft.com/en-us/graph/query-parameters
###############################################################################

#Import-Module and Connect to Microsoft Graph
Import-Module Microsoft.Graph.Reports
Connect-MgGraph -Scope AuditLog.Read.All,Directory.Read.All

#Get Signins
$Signins  = Get-MgAuditLogSignIn
$Signins.Count

#Show Details of one Record
$Signins[0] | Format-List

#List RiskState
$Signins | Where-Object {$_.RiskState -ne "none"}

#Search for a specific User
$Signins  = Get-MgAuditLogSignIn -Filter "startsWith(userPrincipalName,'a.bohren@icewolf.ch')" 
$Signins.Count
$Signins  = Get-MgAuditLogSignIn -Filter "startsWith(userPrincipalName,'a.bohren@icewolf.ch')" -All
$Signins.Count

#List Details
$Signins | Where-Object {$_.ConditionalAccessStatus -eq "success"} | sort-Object CreatedDateTime -Descending | Format-Table UserPrincipalName, ClientAppUsed, AppDisplayName, ConditionalAccessStatus, CreatedDateTime

#Get latest 10 Signins for a specific User
$Signins  = Get-MgAuditLogSignIn -Filter "startsWith(userPrincipalName,'a.bohren@icewolf.ch')" -Top 10 
$Signins | sort-Object CreatedDateTime -Descending | Format-Table UserPrincipalName, ClientAppUsed, AppDisplayName, ConditionalAccessStatus, CreatedDateTime
