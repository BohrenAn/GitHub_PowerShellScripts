###############################################################################
# Script to monitor M365 Service Health and Issues using MS Graph API
# Requires:
# - MSAL.PS Module for PowerShell 5.1
# - PSMSALNet Module for PowerShell 7.x
# - App Registration with Certificate Authentication and following API Permissions:
#   - ServiceHealth.Read.All
#   - ServiceMessage.Read.All
#   - Mail.Send (if SendMailViaGraphAPI is set to true) or use Exchange RBAC for Applications see below
# - Adjust TenantID, AppID and Certificate Thumbprint and Email Settings in the Configuration Section
# V1.0 - 2025-11-26 - Initial Version - Andres Bohren
# V1.1 - 2025-12-03 - Added State to track changes - Andres Bohren
# V1.2 - 2026-01-25 - Cleaned up and added comments - Andres Bohren
###############################################################################
# Setup Notes
###############################################################################
# Setup Exchange Online RBAC for Applications to send Mail without Graph API
# https://blog.icewolf.ch/archive/2025/12/03/exchange-online-app-access-policies-are-replaced-by-RBAC-for-applications/
# Create Exchange Service Principal
# $AppID = "29581967-458b-4c7a-a4f7-03fa440c0e13" #ServiceCommunications
# $AppObjectID = "1adfae9a-9d30-49c1-b786-0f3dd70f8a1e" #ObjectID of the Enterprise App
# $DisplayName = "EXO Serviceprincipal ServiceCommunications"
# New-ServicePrincipal -AppId $AppID -ObjectId $AppObjectID -DisplayName $DisplayName
#
###############################################################################
# New-ManagementScope
###############################################################################
# New-ManagementScope -Name "User1" -RecipientRestrictionFilter "PrimarySmtpAddress -eq 'User1@domain.tld'"
# Get-ManagementScope
#
##############################################################################
#New-ManagementRoleAssignment
###############################################################################
# $SP = Get-ServicePrincipal | Where-Object {$_.AppId -eq $AppID}
# $ServiceId = $SP.ObjectId
# New-ManagementRoleAssignment -App $ServiceId -Role "Application Mail.Send" -CustomResourceScope "User1"
# Get-ManagementRoleAssignment | Where-Object {$_.Role -eq "Application Mail.Send" -and $_.App -eq "$ServiceId"}
###############################################################################
# END Setup Notes
###############################################################################

###############################################################################
# Variables
###############################################################################
<# December 2025
Exchange Online
Microsoft Entra
Microsoft 365 suite
SharePoint Online
Dynamics 365 Apps
Basic Mobility and Security
Planner
Sway
Power BI
Microsoft Intune
Microsoft OneDrive
Microsoft Teams
Microsoft Bookings
Microsoft 365 for the web
Microsoft 365 apps
Power Apps in Microsoft 365
Microsoft Power Automate
Microsoft Power Automate in Microsoft 365
Microsoft Forms
Microsoft Defender XDR
Project for the web
Microsoft Stream
Universal Print
Microsoft Viva
Windows Autopatch
Power Platform
Microsoft Copilot (Microsoft 365)
Microsoft Purview
Microsoft Clipchamp 
Microsoft 365 Copilot Chat
Microsoft Copilot (Power Platform)
#>

### START Configuration Section ###

#Create Array of Services to monitor
[array]$ArrayServices = "Exchange Online", "Microsoft Entra", "Microsoft Intune", "Microsoft 365 for the web", "Microsoft 365 apps"

# Entra App  Details
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppID = "29581967-458b-4c7a-a4f7-03fa440c0e13" #ServiceCommunications
$CertificateThumbprint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3"  #CN=O365Powershell4

#Log Purge
[int]$LogPurgeDays = 30

#Email Settings
[string]$MailSender = "postmaster@icewolf.ch"
[string]$MailRecipient = "a.bohren@icewolf.ch"
[string]$SMTPServer = "smtprelay.corp.icewolf.ch"
[bool]$SendMailViaGraphAPI = $true

### END Configuration Section ###

#Create HTML Template
$HTML = @"
<!DOCTYPE html>
<html>
<style>
BODY{font-family: Arial; font-size: 10pt;}
table, th, td {
    border: 1px solid black;
    border-collapse: collapse;
}
th {
    padding: 5px;
    text-align: left;
    background-color: #a8a7a7ff;
}
tr.yellow {background-color: #f0e10e;}
tr.green {background-color: #34eb57;}
</style>
<body>
<h1>Services Health</h1>
%ServiceHealthTable%
<h1>Issues</h1>
<h2>New Issues %NewIssueCount%</h2>
%NewIssuesTable%
<h2>Open Issues %OpenIssueCount%</h2>
%OpenIssuesTable%
<h2>Closed Issues %ClosedIssueCount%</h2>
%ClosedIssuesTable%
</body>
</html>
"@

###############################################################################
# Function Delete *.log files older than X days
###############################################################################
Function Remove-OldLogFiles {
    Param (
        [int]$DaysOld
    )

    $CurrentDate = Get-Date
    $Files = Get-ChildItem -Path ".\" -Filter *.log

    Foreach ($File in $Files) {
        $FileAge = ($CurrentDate - $File.CreationTime).Days
        If ($FileAge -gt $DaysOld) {
            Remove-Item -Path $File.FullName -Force
            Write-Host "Deleted log file: $($File.FullName)" -ForegroundColor Green
        }
    }
}

###############################################################################
# Function WriteLog
###############################################################################
Function Write-Log {
    PARAM (
        [string]$LogMessage
    )
    $Date = $(get-date -format "dd.MM.yyyy HH:mm:ss")
    $ShortDate = (Get-Date).ToString('yyyy-MM-dd')
    Add-Content -Path ".\M365ServiceMonitoring_$ShortDate.log" -Value ($Date + " " + $LogMessage)     
}

###############################################################################
# Send Mail via Graph API
###############################################################################
# https://blog.icewolf.ch/archive/2022/03/15/simple-example-of-sending-mail-via-microsoft-graph/
function Send-MailGraphApi {
    PARAM (
        [Parameter(Mandatory = $true)][string]$MailSender,
        [Parameter(Mandatory = $true)][string]$MailRecipient,
        [Parameter(Mandatory = $true)][string]$Subject,
        [Parameter(Mandatory = $true)][string]$MessageBody
    )

    #Adjust new lines for JSON body
    $MessageBody = $MessageBody | ConvertTo-Json

    $URI = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"
    $ContentType = "application/json"
    $Headers = @{"Authorization" = "Bearer " + $AccessToken }
    $Body = @"
{
    "message": {
        "subject": "$Subject",
        "body": {
            "contentType": "HTML",
            "content": $MessageBody
        },
        "toRecipients": [
            {
                "emailAddress": {
                    "address": "$MailRecipient"
                }
            }
        ]
    }
}
"@

    #DEBUG
    #Write-Host "URI: $URI" -ForegroundColor Magenta
    #Write-Host "Headers: $Headers" -ForegroundColor Magenta
    #Write-Host "Body: $Body" -ForegroundColor Magenta

    #Send Actual Mail
    $result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType
    If ($null -ne $result)
    {
        Write-Log -LogMessage "Mail sending failed"
        Write-Host "Mail has been sucessufully sent"
    }
    Else {
        Write-Log -LogMessage "Mail sending failed"
        Write-Host "Mail sending failed"
    }
}

###############################################################################
# Start Main Script
###############################################################################
Write-Log -LogMessage "### M365 Service Monitoring Script started. ###"
Write-Host "M365 Service Monitoring Script started." -ForegroundColor Cyan

Write-Log -LogMessage "Removing log files older than $LogPurgeDays days."
Write-Host "Removing log files older than $LogPurgeDays days." -ForegroundColor Cyan
Remove-OldLogFiles -DaysOld $LogPurgeDays

# Detect if running in PowerShell 5.1 or PowerShell 7.x
$PSVersion = $PSVersionTable.PSVersion.Major
Write-Log -LogMessage "Detected PowerShell Version: $PSVersion"
Write-Host "Detected PowerShell Version: $PSVersion" -ForegroundColor Cyan

If ($PSVersion -lt 6) {
    Write-Log -LogMessage "Running in PowerShell 5.1"
    Write-Host "Running in PowerShell 5.1" -ForegroundColor Cyan

    ###############################################################################
    # Get Access Token using MSAL.PS (PowerShell 5.1)
    ###############################################################################
    Import-Module MSAL.PS
    $ClientCertificate = Get-Item Cert:\CurrentUser\My\$CertificateThumbprint
    $Scope = "https://graph.microsoft.com/.default"
    $Token = Get-MsalToken -clientID $AppID -ClientCertificate $ClientCertificate -tenantID $tenantID -Scope $Scope
    $AccessToken = $Token.AccessToken
    $AccessToken
    #$AccessToken
    #Get-JWTDetails -token $AccessToken

} Else {
    Write-Log -LogMessage "Running in PowerShell 7.x"
    Write-Host "Running in PowerShell 7.x" -ForegroundColor Cyan

    ###############################################################################
    # Get Access Token using PSMSALNet (PowerShell 7.x)
    ###############################################################################
    Write-Log -LogMessage "Getting Access Token using PSMSALNet."
    Write-Host "Getting Access Token using PSMSALNet." -ForegroundColor Cyan

    Import-Module PSMSALNet
    $Certificate = Get-ChildItem -Path cert:\CurrentUser\my\$CertificateThumbprint

    $HashArguments = @{
        ClientId          = $AppID
        ClientCertificate = $Certificate
        TenantId          = $TenantId
        Resource          = "GraphAPI"
    }
    $Token = Get-EntraToken -ClientCredentialFlowWithCertificate @HashArguments
    $AccessToken = $Token.AccessToken
    #$AccessToken
    #Get-JWTDetails -token $AccessToken
}

###############################################################################
# Service Healh Overview
###############################################################################
Write-Log -LogMessage "Getting Service Health Overview."
Write-Host "Getting Service Health Overview." -ForegroundColor Cyan

$URI = "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/healthOverviews/"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer " + $AccessToken }
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$ServiceHealth = $result.Value | Where-Object { $ArrayServices -match $_.Service }

#Create HTML Table
$ServiceHealthTable = "<table><tr><th>Service</th><th>Status</th></tr>"

#Loop throuh Services
Foreach ($Line in $ServiceHealth)
{
    $Service = $Line.service
    $Status = $Line.status
    If ($Status -eq "serviceOperational")
    {
        $ServiceHealthTable = $ServiceHealthTable + "<tr class='green'><td>$Service</td><td>$Status</td></td>"
    }
    Else {
        $ServiceHealthTable = $ServiceHealthTable + "<tr class='yellow'><td>$Service</td><td>$Status</td></td>"
    }
    #$ServiceHealthTable = $ServiceHealthTable + "<tr><td>$Service</td><td>$Status</td></td>"
}
$ServiceHealthTable = $ServiceHealthTable + "</table>"
$HTML = $HTML.Replace("%ServiceHealthTable%", "$ServiceHealthTable")

###############################################################################
# Issues
###############################################################################
Write-Log -LogMessage "Getting Service Issues."
Write-Host "Getting Service Issues." -ForegroundColor Cyan

$URI = "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/issues"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer " + $AccessToken }
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType

###############################################################################
### OpenIssues
###############################################################################
[Array]$APIOpenIssuesArray = $result.value | Where-Object { $ArrayServices -match $_.Service} #-AND $_.endDateTime -eq $null

# Paginate to fetch all available records
Write-host "DEBUG: Nextlink1: $($result.'@odata.NextLink')"
[System.Uri]$NextLink = $($result.'@Odata.NextLink')

While ($null -ne $NextLink) {
    [array]$NextIssues = Invoke-RestMethod -Uri $NextLink -Method GET -Headers $Headers -ContentType $ContentType
    $APIOpenIssuesArray += $NextIssues.value
    $NextIssuesCount = $NextIssues.value.Count
    Write-Host ("{0} Issue Records fetched so far..." -f $NextIssuesCount)
    [System.Uri]$NextLink = $($NextIssues.'@odata.NextLink')
}

#[Array]$OpenIssuesArray = $result.value | Where-Object {$ArrayServices -match $_.Service -AND $_.endDateTime -eq $null } | Sort-Object $_.Service
[Array]$OpenIssuesArray = $APIOpenIssuesArray | Where-Object { $ArrayServices -match $_.Service -AND $_.endDateTime -eq $null } | Sort-Object $_.Service
$OpenIssueCount = $OpenIssuesArray.Count
$HTML = $HTML.Replace("%OpenIssueCount%", "($OpenIssueCount)")

#Compare Open Issues with previous run
If ((Test-Path -Path ".\OpenIssues.xml") -eq $false)
{
    #File Not found
    Write-Log "OpenIssues.xml not found"
    Write-Host "OpenIssues.xml not found"
}
else {
    Write-Host "Compare Open Issues"
    $StoredOpenIssueArray = Import-Clixml -Path ".\OpenIssues.xml"
    $CompareResult = Compare-Object -ReferenceObject $OpenIssuesArray -DifferenceObject $StoredOpenIssueArray #-IncludeEqual
}
#Save OpenIssues
$OpenIssuesArray | Export-Clixml -Path ".\OpenIssues.xml"

If ($OpenIssueCount -eq 0) 
    {
        $HTML = $HTML.Replace("%OpenIssuesTable%", "No Open Issues")
    } Else {
        Write-Log -LogMessage "$OpenIssueCount OPEN Issues found for the selected Services."
        Write-Host "$OpenIssueCount OPEN Issues found for the selected Services." -ForegroundColor Yellow

        # Create HTML Table
        $OpenIssuesTable = "<table>"

        # Loop through Services
        Foreach ($Line in $OpenIssuesArray )
        {
            $ID = $Line.id
            $Service = $Line.service
            $status = $Line.status
            $Title = $Line.title
            $startDateTime = $Line.startDateTime
            $endDateTime = $Line.endDateTime
            $lastModifiedDateTime = $Line.lastModifiedDateTime
            $classification = $Line.classification
            $featureGroup = $Line.featureGroup
            $POSTCount = $Line.Posts.Count
            $LatestPostMessage = $Line.Posts[$POSTCount - 1].description.content

            Write-Log "$ID"
            Write-Host "$ID"

            $OpenIssuesTable = $OpenIssuesTable + "<tr><th>Property</th><th>Value</th></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>ID</td><td>$ID</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>Service</td><td>$Service</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>Status</td><td>$Status</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>Title</td><td>$Title</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>Start</td><td>$startDateTime</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>End</td><td>$endDateTime</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>LastModification</td><td>$lastModifiedDateTime</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>Classification</td><td>$classification</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>FeatureGroup</td><td>$featureGroup</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>MessageCount</td><td>$POSTCount</td></tr>"
            $OpenIssuesTable = $OpenIssuesTable + "<tr><td>LatestMessage</td><td>$LatestPostMessage</td></tr>"
        }
        $OpenIssuesTable = $OpenIssuesTable + "</table>"

        $HTML = $HTML.Replace("%OpenIssuesTable%", "$OpenIssuesTable")
    }

###############################################################################
### New Issues
###############################################################################
[array]$NewIssuesIds = (($CompareResult | Where-Object { $_.SideIndicator -eq "<=" }).InputObject).id
[array]$NewIssuesArray = $APIOpenIssuesArray | Where-Object { $NewIssuesIds -match $_.id }

$NewIssueCount = $NewIssuesArray.Count
$HTML = $HTML.Replace("%NewIssueCount%", "($NewIssueCount)")

If ($NewIssueCount -eq 0) 
{
    $HTML = $HTML.Replace("%NewIssuesTable%", "No New Issues")
} Else {
    Write-Log -LogMessage "$NewIssueCount NEW Issues found for the selected Services."
    Write-Host "$NewIssueCount NEW Issues found for the selected Services." -ForegroundColor Yellow

    # Create HTML Table
    $NewIssuesTable = "<table>"

    # Loop through Services
    Foreach ($Line in $NewIssuesArray )
    {
        $ID = $Line.id
        $Service = $Line.service
        $status = $Line.status
        $Title = $Line.title
        $startDateTime = $Line.startDateTime
        $endDateTime = $Line.endDateTime
        $lastModifiedDateTime = $Line.lastModifiedDateTime
        $classification = $Line.classification
        $featureGroup = $Line.featureGroup
        $POSTCount = $Line.Posts.Count
        $LatestPostMessage = $Line.Posts[$POSTCount - 1].description.content

        Write-Log "$ID"
        Write-Host "$ID"

        $NewIssuesTable = $NewIssuesTable + "<tr><th>Property</th><th>Value</th></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>ID</td><td>$ID</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>Service</td><td>$Service</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>Status</td><td>$Status</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>Title</td><td>$Title</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>Start</td><td>$startDateTime</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>End</td><td>$endDateTime</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>LastModification</td><td>$lastModifiedDateTime</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>Classification</td><td>$classification</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>FeatureGroup</td><td>$featureGroup</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>MessageCount</td><td>$POSTCount</td></tr>"
        $NewIssuesTable = $NewIssuesTable + "<tr><td>LatestMessage</td><td>$LatestPostMessage</td></tr>"
    }
    $NewIssuesTable = $NewIssuesTable + "</table>"

    $HTML = $HTML.Replace("%NewIssuesTable%", "$NewIssuesTable")
}

###############################################################################
### Closed Issues
###############################################################################
[array]$ClosedIssuesIds = (($CompareResult | Where-Object { $_.SideIndicator -eq "=>" }).InputObject).id
[array]$ClosedIssuesArray = $APIOpenIssuesArray | Where-Object { $ClosedIssuesIds -match $_.id }

$ClosedIssuesCount = $ClosedIssuesArray.Count
$HTML = $HTML.Replace("%ClosedIssueCount%", "($ClosedIssuesCount)")

If ($ClosedIssuesCount -eq 0) 
{
    $HTML = $HTML.Replace("%ClosedIssuesTable%", "No Closed Issues")
} Else {
    Write-Log -LogMessage "$ClosedIssuesCount CLOSED Issues found for the selected Services."
    Write-Host "$ClosedIssuesCount CLOSED Issues found for the selected Services." -ForegroundColor Yellow

    # Create HTML Table
    $ClosedIssuesTable = "<table>"

    # Loop through Services
    Foreach ($Line in $ClosedIssuesArray )
    {
        $ID = $Line.id
        $Service = $Line.service
        $status = $Line.status
        $Title = $Line.title
        $startDateTime = $Line.startDateTime
        $endDateTime = $Line.endDateTime
        $lastModifiedDateTime = $Line.lastModifiedDateTime
        $classification = $Line.classification
        $featureGroup = $Line.featureGroup
        $POSTCount = $Line.Posts.Count
        $LatestPostMessage = $Line.Posts[$POSTCount - 1].description.content

        Write-Log "$ID"
        Write-Host "$ID"

        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><th>Property</th><th>Value</th></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>ID</td><td>$ID</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>Service</td><td>$Service</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>Status</td><td>$Status</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>Title</td><td>$Title</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>Start</td><td>$startDateTime</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>End</td><td>$endDateTime</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>LastModification</td><td>$lastModifiedDateTime</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>Classification</td><td>$classification</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>FeatureGroup</td><td>$featureGroup</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>MessageCount</td><td>$POSTCount</td></tr>"
        $ClosedIssuesTable = $ClosedIssuesTable + "<tr><td>LatestMessage</td><td>$LatestPostMessage</td></tr>"
    }
    $ClosedIssuesTable = $ClosedIssuesTable + "</table>"

    $HTML = $HTML.Replace("%ClosedIssuesTable%", "$ClosedIssuesTable")
}

#EXPORT HTML
Write-Log -LogMessage "Exporting HTML Report to M365monitoring.html."
Write-Host "Exporting HTML Report to M365monitoring.html." -ForegroundColor Cyan

$html | Set-Content -Path .\M365monitoring.html

If ($NewIssueCount -gt 0 -or $ClosedIssuesCount -gt 0)
{
    #EXPORT HTML
    $html | Set-Content -Path .\M365monitoring.html

    Write-Log -LogMessage "NEW or CLOSED Issues found for the selected Services."
    Write-Host "NEW or CLOSED Issues found for the selected Services." -ForegroundColor Yellow

    #Send Email
    Write-Log -LogMessage "Sending Email Report to $MailRecipient."
    Write-Host "Sending Email Report to $MailRecipient." -ForegroundColor Cyan  

    If ($SendMailViaGraphAPI -eq $true)
    {
        #Send Mail via Graph API
        Send-MailGraphApi -MailSender $MailSender -MailRecipient $MailRecipient -Subject "M365 Service Monitoring - NEW or CLOSED Issues found" -MessageBody $HTML
    } Else {
        #Send Mail via SMTP Server
        $sendMailMessageSplat = @{
            From       = "$MailSender"
            To         = "$MailRecipient"
            Subject    = "M365 Service Monitoring - NEW or CLOSED Issues found"
            Body       = "$HTML"
            SmtpServer = "$SMTPServer"
        }
        Send-MailMessage @sendMailMessageSplat -BodyAsHtml
    }
}
Else {
    Write-Log -LogMessage "No NEW or CLOSED Issues found selected Services."
    Write-Host "No NEW or CLOSED Issues found selected Services" -ForegroundColor Green
}

Write-Log -LogMessage "### M365 Service Monitoring Script ended. ###"
Write-Host "M365 Service Monitoring Script ended." -ForegroundColor Cyan
