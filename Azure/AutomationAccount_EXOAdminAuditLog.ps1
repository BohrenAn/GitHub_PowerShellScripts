###############################################################################
# Audit Log via Graph API
# https://blog.icewolf.ch/archive/2024/07/15/query-m365-auditlog/
# Export Exchange Admin Audit Log (Add / Remove FullAccess / SendAs Permissions)
# 2026-08-05 - Initial Version - Andres Bohren
# 2025-08-25 - Updated for Azure Automation Account / Runtime Environment - Andres Bohren
###############################################################################
# App Permissions:
# - AuditLog.Read.All
# - AuditLogsQuery.Read.All
###############################################################################
# PowerShell Requirements
# - Azure Runtime Environemen > PowerShell 7.6
# PowerShell Module Requirements
# - Microsoft.Graph.Authentication
###############################################################################
# Install-PSResource -Name DllPickle -Scope CurrentUser
# Import-Module DLLPickle
# Import-DPLibrary
# Connect-MgGraph -Scopes 'Application.Read.All' -NoWelcome
# $ServicePrincipalDetails = Get-MgServicePrincipal -Filter "DisplayName eq 'AuditLog'"
# Connect-ExchangeOnline -ShowBanner:$false
# New-ServicePrincipal -AppId $ServicePrincipalDetails.AppId -ObjectID $ServicePrincipalDetails.Id -DisplayName "EXO Serviceprincipal $($ServicePrincipalDetails.Displayname)"
# New-ManagementRoleAssignment -App $ServicePrincipalDetails.Id -Role "Application Mail.Send" -CustomResourceScope "PostmasterGraphRestriction"
###############################################################################
# ManagedIdentity of an Automation Account
# Connect-MgGraph -Scopes 'Application.Read.All' -NoWelcome
# $ManagedIdentityName = "icewolfautomation"
# $MI = Get-MgServicePrincipal -Filter "displayName eq '$ManagedIdentityName'"
# $GraphSP = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
# # Get App Role
# $AppRole = $GraphSP.AppRoles | Where-Object {$_.Value -eq "AuditLog.Read.All" -and $_.AllowedMemberTypes -contains "Application"}
# # Assign Permission
# New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MI.Id -PrincipalId $MI.Id -ResourceId $GraphSP.Id -AppRoleId $AppRole.Id
#
# $AppRole = $GraphSP.AppRoles | Where-Object {$_.Value -eq "AuditLogsQuery.Read.All" -and $_.AllowedMemberTypes -contains "Application"}
# # Assign Permission
# New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MI.Id -PrincipalId $MI.Id -ResourceId $GraphSP.Id -AppRoleId $AppRole.Id
#
# # Exchange RBAC > Managed Identity Mail.Send
# Connect-ExchangeOnline -ShowBanner:$false
# New-ServicePrincipal -AppId $MI.AppId -ObjectID $MI.Id -DisplayName "EXO Serviceprincipal $($MI.Displayname)"
# New-ManagementRoleAssignment -App $MI.Id -Role "Application Mail.Send" -CustomResourceScope "PostmasterGraphRestriction"
###############################################################################
# Entra App > Icewolf
#Write-Output "Connect-MgGraph Entra App"
#$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad" #Icewolf 
#$AppID = "99d8df8d-67b6-4a3a-b915-5cfc835fbfc7" #AuditLog
#$CertificateThumbprint = "FB40D47A0C0A23EA297B44A57272BCED352D0002" #O365Powershell5
#Connect-MgGraph -ClientId $AppID -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint -NoWelcome

Write-Output "Connect-MgGraph using ManagedIdentity"
Connect-MgGraph -Identity -NoWelcome

# Variables
$Sender = "postmaster@icewolf.ch"
$Recipient = "a.bohren@icewolf.ch"

#static
$path = $env:temp
$OutputFile = $Path + "\AuditLog.json"
Write-Output "DEBUG: OutputFile: $OutputFile"


###############################################################################
# Create Search
###############################################################################
Write-Output "Create Array"
$OperationsArray = @()

Write-Output "Create Search"
$DisplayName = "DemoSearch_" + (Get-Date -Format "yyyyMMdd_HHmm")
#[String]$StartDate = [datetime]::parseexact("2026-08-05", "yyyy-MM-dd", $null).Tostring("yyyy-MM-ddT00:00:00Z")
#[String]$EndDate = [datetime]::parseexact("2026-08-06", "yyyy-MM-dd", $null).Tostring("yyyy-MM-ddT00:00:00Z")

# First day of previous month
[String]$StartDate = (Get-Date -Day 1).AddMonths(-1).ToString("yyyy-MM-ddT00:00:00Z")

# Last day of previous month
[String]$EndDate = (Get-Date -Day 1).AddDays(-1).ToString("yyyy-MM-ddT00:00:00Z")

$Uri = "https://graph.microsoft.com/beta/security/auditLog/queries"
$SearchParameters = @{
    displayName         = "$DisplayName"
    filterStartDateTime = "$StartDate"
    filterEndDateTime     = "$EndDate"
    recordTypeFilters     = @("ExchangeAdmin")
    operationFilters = @(
    "Add-MailboxPermission",
    "Remove-MailboxPermission",
    "Add-RecipientPermission",
    "Remove-RecipientPermission"
    )
}

Write-Output "Invoke Search"
$SearchQuery = Invoke-MgGraphRequest -Method POST -Uri $Uri -Body $SearchParameters
$SearchId = $SearchQuery.Id
Write-Output "Searchid: $SearchId"

If ($SearchId -eq $null -or $SearchId -eq "")
{
    Write-Output "No SearchId > Aborting Script"
    Exit
}

###############################################################################
# Check if SearchQuery Suceeded
###############################################################################
Write-Output "Wait for Search to complete"
#$AuditSearch = Get-MgBetaSecurityAuditLogQuery -AuditLogQueryId $SearchId | fl
#$AuditSearch = Get-MgBetaSecurityAuditLogQuery -AuditLogQueryId $SearchId
$URI = "https://graph.microsoft.com/beta/security/auditLog/queries/$searchId"
$AuditSearch = Invoke-MgGraphRequest -Method "GET" -Uri $Uri
$AuditSearchStatus = $AuditSearch.Status
Write-Output "Status: $AuditSearchStatus"
While ($AuditSearch.Status -ne "succeeded")
{
    #$AuditSearch = Get-MgBetaSecurityAuditLogQuery -AuditLogQueryId $SearchId
    $URI = "https://graph.microsoft.com/beta/security/auditLog/queries/$searchId"
    $AuditSearch = Invoke-MgGraphRequest -Method "GET" -Uri $Uri
    $AuditSearchStatus = $AuditSearch.Status
    Write-Output "Status: $AuditSearchStatus"
    Start-Sleep -Seconds 60

    If ($AuditSearchStatus -eq "failed")
    {
        Write-Output "Audit Search failed - aborting Script"
        Exit
    }
}

###############################################################################
# Get Data from SearchQuery
###############################################################################
Write-Output "Loop through results"
$Uri = ("https://graph.microsoft.com/beta/security/auditLog/queries/{0}/records" -f $SearchId)
[array]$SearchRecords = Invoke-MgGraphRequest -Uri $Uri -Method GET
$AuditRecords += $SearchRecords.value

# Paginate to fetch all available audit records
$NextLink = $SearchRecords.'@Odata.NextLink'
While ($null -ne $NextLink) {
    $SearchRecords = $null
    [array]$SearchRecords = Invoke-MgGraphRequest -Uri $NextLink -Method GET 
    $AuditRecords += $SearchRecords.value
    Write-Host ("{0} audit records fetched so far..." -f $AuditRecords.count)
    $NextLink = $SearchRecords.'@odata.NextLink' 
} 
$AuditRecordCount = $AuditRecords.Count
Write-Output "Audit Records found: $AuditRecordCount"

#$AuditRecords.Auditdata[0]
#$AuditRecords.Auditdata | ConvertTo-Json -Depth 5 | Set-Content -path C:\Temp\AuditLog.json

#Filter Output
$AuditRecords.AuditData |
    Select-Object CreationTime,
                UserKey,
                UserId,
                ObjectId,
                Operation,
                @{
                    Name = 'AccessRights'
                    Expression = {
                        ($_.Parameters | Where-Object Name -eq 'AccessRights').Value
                    }
                } |
    ConvertTo-Json -Depth 5 |
Set-Content $OutputFile

###############################################################################
# Send Admin Email
###############################################################################
Write-Output "Send Admin Mail"

$FileSize = (Get-Item $Outputfile).Length / 1KB
Write-Output "FileSize: $FileSize" 

# Better code is to use .NET to convert to BASE64
$Base64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$OutputFile"))


$URI = "https://graph.microsoft.com/v1.0/users/$sender/sendMail"

$Body = @"
{
    "message": {
    "subject": "EXO Audit Log",
    "body": {
        "contentType": "Text",
        "content": "The Exchange Admin Audit Log has been attached"
    },
    "toRecipients": [
        {
        "emailAddress": {
            "address": "$Recipient"
        }
    }
    ],
    "attachments": [
    {
        "@odata.type": "#microsoft.graph.fileAttachment",
        "name": "AuditLog.json",
        "contentType": "application/json",
        "contentBytes": "$Base64"
    }
    ]
    }
}
"@

$ContentType = "application/json"
$Result = Invoke-MgGraphRequest -URI $URI -Method POST -Body $Body -ContentType $ContentType

Write-Output "Script Finished"