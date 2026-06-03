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
# V1.3 - 2026-04-28 - Multiple Recipients supported - Andres Bohren
# V1.4 - 2026-05-18 - Added ConfigVariable AuthTokenWithoutModule See Function Get-AuthTokenWithoutModule for details - Andres Bohren
# V1.5 - 2026-05-19 - Added Modern HTML / Page Reload - Andres Bohren
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
[array]$ArrayServices = "Exchange Online", "Microsoft Entra", "Microsoft Intune", "Microsoft 365 for the web", "Microsoft 365 apps", "SharePoint Online", "Microsoft OneDrive", "Microsoft Teams", "Planner", "Microsoft Purview"

# Entra App  Details
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppID = "29581967-458b-4c7a-a4f7-03fa440c0e13" #ServiceCommunications
$CertificateThumbprint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3"  #CN=O365Powershell4

# Auth Token Without Module
[bool]$AuthTokenWithoutModule = $true

#Log Purge
[int]$LogPurgeDays = 30

#Email Settings
[string]$MailSender = "postmaster@icewolf.ch"
[array]$MailRecipient = "a.bohren@icewolf.ch","postmaster@icewolf.ch"
[string]$SMTPServer = "smtprelay.corp.icewolf.ch"
[bool]$SendMailViaGraphAPI = $true

### END Configuration Section ###

#Create HTML Template
$HTML = @"
<!DOCTYPE html>
<html>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="300">
<style>
:root {
    --bg: #f4f7fb;
    --surface: #ffffff;
    --text: #1d2939;
    --muted: #667085;
    --line: #d0d5dd;
    --accent: #0b63f6;
    --new: #1565c0;
    --open: #b54708;
    --closed: #027a48;
}

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    padding: 24px;
    background: radial-gradient(circle at 5% 5%, #ffffff 0%, #f4f7fb 55%, #e9eef8 100%);
    font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
    color: var(--text);
    font-size: 10pt;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
}

h1 {
    margin: 0 0 12px 0;
    font-size: 28px;
    letter-spacing: 0.2px;
}

h2 {
    margin: 24px 0 10px 0;
    font-size: 20px;
}

.summary-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 12px;
    margin: 8px 0 20px 0;
}

.summary-card {
    background: var(--surface);
    border: 1px solid var(--line);
    border-left-width: 6px;
    border-radius: 12px;
    padding: 14px 16px;
    box-shadow: 0 8px 24px rgba(16, 24, 40, 0.08);
}

.summary-card .label {
    display: block;
    font-size: 34px;
    text-transform: uppercase;
    letter-spacing: 0.7px;
    color: var(--muted);
    margin-bottom: 6px;
}

.summary-card .value {
    font-size: 34px;
    line-height: 1;
    font-weight: 700;
}

.summary-card.new { border-left-color: var(--new); }
.summary-card.open { border-left-color: var(--open); }
.summary-card.closed { border-left-color: var(--closed); }

.panel {
    background: var(--surface);
    border: 1px solid var(--line);
    border-radius: 12px;
    padding: 14px;
    box-shadow: 0 8px 24px rgba(16, 24, 40, 0.05);
}

table {
    width: 100%;
    border: 1px solid var(--line);
    border-collapse: collapse;
    background: #fff;
}

th,
td {
    border: 1px solid var(--line);
    padding: 8px;
    text-align: left;
    vertical-align: top;
}

th {
    background-color: #e8eef9;
    color: #1f2a44;
}

tr.yellow { background-color: #ffd84d; }
tr.green { background-color: #4ade80; }

</style>
<body>
<div class="container">
<h1>Services Health</h1>

<!-- Outlook / Outlook Mobile safe summary cards (tables + inline-friendly styles) -->
<table class="summary-table" role="presentation" cellpadding="0" cellspacing="0" border="0">
    <tr>
        <td class="summary-col" width="33.33%" valign="top" style="padding:0 6px 12px 0; border:0;">
            <table class="summary-card-table" role="presentation" cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td width="6" bgcolor="#1565c0" style="width:6px; font-size:0; line-height:0; padding:0; border:0;">&nbsp;</td>
                    <td style="padding:14px 16px; border:0;">
                        <span class="summary-label">New Issues</span>
                        <div class="summary-value">%NewIssueCount%</div>
                    </td>
                </tr>
            </table>
        </td>

        <td class="summary-col" width="33.33%" valign="top" style="padding:0 6px 12px 6px; border:0;">
            <table class="summary-card-table" role="presentation" cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td width="6" bgcolor="#b54708" style="width:6px; font-size:0; line-height:0; padding:0; border:0;">&nbsp;</td>
                    <td style="padding:14px 16px; border:0;">
                        <span class="summary-label">Open Issues</span>
                        <div class="summary-value">%OpenIssueCount%</div>
                    </td>
                </tr>
            </table>
        </td>

        <td class="summary-col" width="33.33%" valign="top" style="padding:0 0 12px 6px; border:0;">
            <table class="summary-card-table" role="presentation" cellpadding="0" cellspacing="0" border="0">
                <tr>
                    <td width="6" bgcolor="#027a48" style="width:6px; font-size:0; line-height:0; padding:0; border:0;">&nbsp;</td>
                    <td style="padding:14px 16px; border:0;">
                        <span class="summary-label">Closed Issues</span>
                        <div class="summary-value">%ClosedIssueCount%</div>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</div>

<div class="panel">
<h1>Services Health</h1>
%ServiceHealthTable%
</div>

<h1>Issues</h1>
<h2>New Issues %NewIssueCount%</h2>
<div class="panel">
%NewIssuesTable%
</div>
<h2>Open Issues %OpenIssueCount%</h2>
<div class="panel">
%OpenIssuesTable%
</div>
<h2>Closed Issues %ClosedIssueCount%</h2>
<div class="panel">
%ClosedIssuesTable%
</div>
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
        [Parameter(Mandatory = $true)][array]$MailRecipient,
        [Parameter(Mandatory = $true)][string]$Subject,
        [Parameter(Mandatory = $true)][string]$MessageBody
    )

    #Adjust new lines for JSON body
    #$MessageBody = $MessageBody | ConvertTo-Json

    $URI = "https://graph.microsoft.com/v1.0/users/$MailSender/sendMail"
    $ContentType = "application/json"
    $Headers = @{"Authorization" = "Bearer " + $AccessToken }

    $ToRecipients = foreach ($Recipient in $MailRecipient) 
    {
        @{
            emailAddress = @{
                address = $Recipient
            }
        }
    }

    $BodyObject = @{
        message = @{
            subject = $Subject
            body = @{
                contentType = "HTML"
                content     = $MessageBody
            }
            toRecipients = $ToRecipients
        }
    }

    $Body = $BodyObject | ConvertTo-Json -Depth 6

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
# Native Login with Certificate (Application Permission)
# https://learn.microsoft.com/en-us/answers/questions/346048/how-to-get-access-token-from-client-certificate-ca
###############################################################################
function Get-AuthTokenWithoutModule {
    PARAM (
        [Parameter(Mandatory = $true)][string]$TenantName,
        [Parameter(Mandatory = $true)][string]$AppId,
        [Parameter(Mandatory = $true)][string]$Thumbprint,
        [Parameter(Mandatory = $true)][string]$Scope
    )

    $Certificate = Get-Item "Cert:\CurrentUser\My\$Thumbprint" #O365Powershell4.cer
    #$Scope = "6a8b4b39-c021-437c-b060-5a14a3fd65f3/.default" # Example: "https://graph.microsoft.com/.default"

    # Create base64 hash of certificate
    $CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())

    # Create JWT timestamp for expiration
    $StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
    $JWTExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
    $JWTExpiration = [math]::Round($JWTExpirationTimeSpan,0)

    # Create JWT validity start timestamp  
    $NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds  
    $NotBefore = [math]::Round($NotBeforeExpirationTimeSpan,0)

    # Create JWT header
    $JWTHeader = @{
        alg = "RS256"
        typ = "JWT"
        # Use the CertificateBase64Hash and replace/strip to match web encoding of base64  
        x5t = $CertificateBase64Hash -replace '\+','-' -replace '/','_' -replace '='  
    }

    # Create JWT payload
    $JWTPayLoad = @{
        # What endpoint is allowed to use this JWT  
        aud = "https://login.microsoftonline.com/$TenantName/oauth2/token"  

        # Expiration timestamp
        exp = $JWTExpiration

        # Issuer = your application
        iss = $AppId

        # JWT ID: random guid
        jti = [guid]::NewGuid()

        # Not to be used before
        nbf = $NotBefore

        # JWT Subject
        sub = $AppId
    }

    # Convert header and payload to base64
    $JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))
    $EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)

    $JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
    $EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)

    # Join header and Payload with "." to create a valid (unsigned) JWT
    $JWT = $EncodedHeader + "." + $EncodedPayload

    # Get the private key object of your certificate
    $PrivateKey = ([System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate))

    # Define RSA signature and hashing algorithm
    $RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
    $HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256

    # Create a signature of the JWT
    $Signature = [Convert]::ToBase64String(
        $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding)
    ) -replace '\+','-' -replace '/','_' -replace '='

    # Join the signature to the JWT with "."
    $JWT = $JWT + "." + $Signature

    # Create a hash with body parameters
    $Body = @{
        client_id = $AppId
        client_assertion = $JWT
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        scope = $Scope
        grant_type = "client_credentials"
    }

    $Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

    # Use the self-generated JWT as Authorization
    $Header = @{
        Authorization = "Bearer $JWT"
    }

    # Splat the parameters for Invoke-Restmethod for cleaner code
    $PostSplat = @{
        ContentType = 'application/x-www-form-urlencoded'
        Method = 'POST'
        Body = $Body
        Uri = $Url
        Headers = $Header
    }

    $Token = Invoke-RestMethod @PostSplat
    $AccessToken = $Token.access_token
    return $AccessToken
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

If ($AuthTokenWithoutModule -eq $true)
{
    Write-Log -LogMessage "Getting Access Token using native JWT creation without external module."
    Write-Host "Getting Access Token using native JWT creation without external module." -ForegroundColor Cyan

    $AccessToken = Get-AuthTokenWithoutModule -TenantName $TenantId -AppId $AppID -Thumbprint $CertificateThumbprint -Scope "https://graph.microsoft.com/.default"
    #$AccessToken
    #Get-JWTDetails -token $AccessToken
} else {

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
