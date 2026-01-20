###############################################################################
# DEMO of Mailhandling with GraphAPI (Mail / Calendar / Personal contacts)
# 01.03.2022 V0.1 - Initial Draft - Andres Bohren
###############################################################################

###############################################################################
# Limiting application permissions to specific Exchange Online mailboxes
# https://docs.microsoft.com/en-us/graph/auth-limit-mailbox-access
#
# Limit Microsoft Graph Access to specific Exchange Mailboxes
#https://blog.icewolf.ch/archive/2021/02/06/limit-microsoft-graph-access-to-specific-exchange-mailboxes.aspx
###############################################################################
Connect-ExchangeOnline -ShowBanner:$false
$GroupName = "PostmasterGraphRestriction"
$MailEnabledSecurityGroup = New-DistributionGroup -Name $GroupName -Members "postmaster@icewolf.ch" -Type "Security" -PrimarySmtpAddress "$GroupName@icewolf.ch"
$GroupPrimarySMTPAddress =  $MailEnabledSecurityGroup.PrimarySmtpAddress

$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
New-ApplicationAccessPolicy -AccessRight RestrictAccess -AppId "AppID" -PolicyScopeGroupId "$GroupPrimarySMTPAddress" -Description "Restrict this app to members of this Group"
Get-ApplicationAccessPolicy
Get-ApplicationAccessPolicy | Where-Object {$_.Appid -eq "c1a5903b-cd73-48fe-ac1f-e71bde968412"}
Test-ApplicationAccessPolicy -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -Identity postmaster@icewolf.ch
Test-ApplicationAccessPolicy -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -Identity SharedMBX@icewolf.ch


###############################################################################
#Create SelfSignedCertificate
# https://docs.microsoft.com/en-us/powershell/module/pki/new-selfsignedcertificate?view=windowsserver2022-ps
###############################################################################
Get-ChildItem -Path cert:\CurrentUser\my | Format-Table
$Subject = "DemoCert"
$NotAfter = (Get-Date).AddMonths(+24)
$Cert = New-SelfSignedCertificate -Subject $Subject -CertStoreLocation "Cert:\CurrentUser\My" -KeySpec Signature -NotAfter $Notafter -KeyExportPolicy Exportable
#CD cert:\localmachine\my    #(computer cert)   
#cd cert:\currentuser\my    #(user cert)
#$cert =ls | where {$_.Subject -match "DemoCert"}
#certmgr.msc
$ThumbPrint = $Cert.ThumbPrint

###############################################################################
#Export DER Certificate
###############################################################################
$Subject = "DemoCert"
$CurrentLocation = (Get-Location).path
Export-Certificate -Filepath "$CurrentLocation\$Subject-DER.cer" -cert $Cert -type CERT -NoClobber 
Get-ChildItem -Path cert:\CurrentUser\my\$ThumbPrint | Export-Certificate -FilePath "$CurrentLocation\$Subject-DER.cer"
Get-ChildItem -Path cert:\CurrentUser\my\ | Where-Object {$_.Subject -eq "CN=$Subject"} | Export-Certificate -FilePath "$CurrentLocation\$Subject-DER.cer"

###############################################################################
#Export Base64 Certificate
###############################################################################
$ThumbPrint = "EC5E821C553DA9564394844B4C1076B5F8BB7F6D"
$Base64 = [convert]::tobase64string((get-item cert:\currentuser\my\$ThumbPrint).RawData)
$Base64Block = $Base64 |
ForEach-Object {
    $line = $_

    for ($i = 0; $i -lt $Base64.Length; $i += 64)
    {
        $length = [Math]::Min(64, $line.Length - $i)
        $line.SubString($i, $length)
    }
}
$base64Block2 = $Base64Block | Out-String

$Value = "-----BEGIN CERTIFICATE-----`r`n"
$Value += "$Base64Block2"
$Value += "-----END CERTIFICATE-----"
$Value
$CurrentLocation = (Get-Location).path
Set-Content -Path "$CurrentLocation\$Subject-BASE64.cer" -Value $Value

###############################################################################
#Export PFX Certificate
#https://docs.microsoft.com/en-us/powershell/module/pki/export-pfxcertificate?view=windowsserver2022-ps
###############################################################################
$PFXPassword = ConvertTo-SecureString -String "SecretPa$$word!" -Force -AsPlainText
$Cert = Get-ChildItem -Path cert:\CurrentUser\my\$ThumbPrint 
$Cert = Get-ChildItem -Path cert:\CurrentUser\my\ | Where-Object {$_.Subject -eq "CN=$Subject"}
Export-PfxCertificate -Cert $cert -FilePath "C:\Git_WorkingDir\$Subject.pfx" -Password $PFXPassword

###############################################################################
# Exchange Online Role Based Access Control (RBAC) for Applications
# https://blog.icewolf.ch/archive/2023/01/05/exchange-online-role-based-access-control-rbac-for-applications/
###############################################################################
# The most important Takeaways are:
# - The Preview is now available to all customers in our worldwide multi-tenant environment, and we expect to reach general availability in H1 2023
#- This feature extends our current RBAC model and will replace the current Application Access Policy feature.
#- Service Principals representing apps must be manually created in Exchange Online during the Preview, but this process will be automated to offer a more efficient user experience at GA
#- The Preview provides two resource scoping mechanisms, both of which are supported by Exchange RBAC: management scopes, and admin units

###############################################################################
# Get AccessToken with MSAL - has been depreciated 22.09.2023
###############################################################################
#Install-Module MSAL.PS
Clear-MsalTokenCache

Import-Module MSAL.PS
$TenantId = "icewolfch.onmicrosoft.com"
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$Scope = "https://graph.microsoft.com/.default" 

#Authenticate with ClientSecret
$ClientSecret = ConvertTo-SecureString "YourClientSecret" -AsPlainText -Force
$Token = Get-MsalToken -ClientId $AppID -ClientSecret $ClientSecret -TenantId $TenantID -Scope $Scope -RedirectUri $RedirectUri
$AccessToken = $Token.AccessToken
$AccessToken

#Authenticate with Certificate
$CertificateThumbprint = "4F1C474F862679EC35650824F73903041E1E5742" #O365Powershell2.cer
$Certificate = Get-ChildItem -Path cert:\CurrentUser\my\$CertificateThumbprint
$Token = Get-MsalToken -ClientId $AppID -ClientCertificate $Certificate -TenantId $TenantID -Scope $Scope -RedirectUri $RedirectUri
$AccessToken = $Token.AccessToken
$AccessToken

#Delegated
Import-Module MSAL.PS
Clear-MsalTokenCache
#$Token = Get-MsalToken -DeviceCode -ClientId $AppID -TenantId $TenantID -RedirectUri $RedirectUri
$Token = Get-MsalToken -ClientId $AppID -TenantId $TenantID -RedirectUri $RedirectUri
$AccessToken = $Token.AccessToken
$AccessToken

#Interactive
$Token = Get-MsalToken -ClientId $AppID -TenantId $TenantId -Scope $Scope -Interactive #-ErrorAction SilentlyContinue
$AccessToken = $Token.AccessToken
$AccessToken

###############################################################################
# PSMSALNet as a Replacement of MSAL.PS
###############################################################################
#Prerequisit PowerShell 7.4
Install-Module PSMSALNet

#Setting up the Variables for all Examples
Import-Module PSMSALNet
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

#Authenticate with ClientSecret
$ClientSecret = "YourClientSecret"
$HashArguments = @{
    ClientId = $AppID
    ClientSecret = $ClientSecret
    TenantId = $TenantId
    Resource = "GraphAPI"
}
$Token = Get-EntraToken -ClientCredentialFlowWithSecret @HashArguments
$AccessToken = $Token.AccessToken
$AccessToken

#Authenticate with Certificate
$CertificateThumbprint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4.cer
$Certificate = Get-ChildItem -Path cert:\CurrentUser\my\$CertificateThumbprint
$HashArguments = @{
    ClientId = $AppID
    ClientCertificate = $Certificate
    TenantId = $TenantId
    Resource = "GraphAPI"
}
$Token = Get-EntraToken -ClientCredentialFlowWithCertificate @HashArguments
$AccessToken = $Token.AccessToken
$AccessToken

# DeviceCode
$HashArguments = @{
    ClientId = $AppID
    TenantId = $TenantId
    Resource = "GraphAPI"
    Permissions = @("Mail.ReadWrite", "Mail.Send", "Calendars.ReadWrite", "Contacts.ReadWrite", "Tasks.ReadWrite")
    verbose = $true
}
$Token = Get-EntraToken -DeviceCodeFlow @HashArguments
$AccessToken = $Token.AccessToken
$AccessToken

# Authorization code with PKCE
$HashArguments = @{
    ClientId = $AppID
    TenantId = $TenantId
    RedirectUri = $RedirectUri
    Resource = 'GraphAPI'
    Permissions =  @("Mail.ReadWrite", "Mail.Send", "Calendars.ReadWrite", "Contacts.ReadWrite", "Tasks.ReadWrite")
    verbose = $true
}
$Token = Get-EntraToken -PublicAuthorizationCodeFlow @HashArguments
$AccessToken = $Token.AccessToken
$AccessToken


###############################################################################
# Check Access JWT Token
###############################################################################
# In Browser https://jwt.ms/
Install-Module JWTDetails
Get-InstalledModule JWTDetails
Get-JWTDetails $AccessToken
Get-JWTDetails $AccessToken | Select-Object -ExpandProperty Roles

###############################################################################
# Get AccessToken with Invoke-RestMethod
###############################################################################
#Variables
$ClientID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$ClientSecret = "YourClientSecret"
$tenantID = "icewolfch.onmicrosoft.com"
$scope = "https://graph.microsoft.com/.default"
$authority = "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token"

$Body = @{
    "grant_type"    = "client_credentials";
    "client_id"     = "$ClientID";
    "client_secret" = "$ClientSecret";
    "scope"      = "$scope";
}

#Get AccessToken
Remove-Variable AccessToken
$AccessToken
$Result = Invoke-RestMethod -Method POST -uri $authority -Body $body
$AccessToken = $Result.access_token

###############################################################################
# List Mailbox Folders
# https://docs.microsoft.com/en-us/graph/api/user-list-mailfolders?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Application	Mail.ReadBasic.All, Mail.Read, Mail.ReadWrite

$Mailbox = "Postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/?includeHiddenFolders=true"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$Result.value | Format-Table displayName, id

###############################################################################
# List Child Mailbox Folders
# https://learn.microsoft.com/en-us/graph/api/mailfolder-list-childfolders?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account) Mail.ReadBasic Mail.ReadWrite, Mail.Read
#Delegated (personal Microsoft account) Mail.ReadBasic Mail.ReadWrite, Mail.Read
#Application Mail.ReadBasic.All Mail.ReadWrite, Mail.Read
$Mailbox = "Postmaster@icewolf.ch"
$FolderID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQAuAAAAAADI11bk3aFKQJXy4z2GgQYRAQD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAA=" #Posteing
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderId/ChildFolders"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$Result.value | Format-List displayName, id

###############################################################################
# Permanently Delete Mailbox Folder
# https://learn.microsoft.com/en-us/graph/api/mailfolder-permanentdelete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "Postmaster@icewolf.ch"
$FolderID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQAuAAAAAADI11bk3aFKQJXy4z2GgQYRAQD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAA=" #Posteing
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/permanentDelete"
$ChildFolderID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQAuAAAAAADI11bk3aFKQJXy4z2GgQYRAQD9DAdvUOIbRK2TMu1gBCF9AARIILy3AAA=" #Posteing/Subfolder
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/childFolders/$ChildFolderID/permanentDelete"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -ContentType $ContentType
$Result

###############################################################################
# List Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/user-list-messages?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Application	Mail.ReadBasic.All, Mail.Read, Mail.ReadWrite

$Mailbox = "Postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages"
$FolderID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQAuAAAAAADI11bk3aFKQJXy4z2GgQYRAQD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAA="
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$Result.value[0] | Format-List
$Result.value | Format-List id,receivedDateTime, subject, hasAttachments, importance, internetMessageId,isRead

###############################################################################
# List Mailbox Message Filtered by InternetMessageId
###############################################################################
$internetMessageId = "<GV0P278MB074937BA8A5E19355D567F9CA642A@GV0P278MB0749.CHEP278.PROD.OUTLOOK.COM>"
$Filter = "?`$filter=internetMessageId eq '" + $internetMessageId + "'"
$Mailbox = "Postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages"
$FolderID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQAuAAAAAADI11bk3aFKQJXy4z2GgQYRAQD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAA="
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages/$Filter"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$Result.value[0] | Format-List
$Result.value | Format-List id,receivedDateTime, subject, hasAttachments, importance, internetMessageId,isRead

###############################################################################
# Get Mailbox Message with Message ID
###############################################################################
$ID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQBGAAAAAADI11bk3aFKQJXy4z2GgQYRBwD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAD9DAdvUOIbRK2TMu1gBCF9AAbTve6hAAA="
$Mailbox = "Postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages"
$FolderID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQAuAAAAAADI11bk3aFKQJXy4z2GgQYRAQD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAA="
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages/$ID"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$Result | Format-List id,receivedDateTime, subject, hasAttachments, importance, internetMessageId,isRead

###############################################################################
# Create Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/user-post-messages?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "Postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$FolderID/messages"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
    "subject":"Did you see last night's game?",
    "importance":"Low",
    "body":{
        "contentType":"HTML",
        "content":"They were <b>awesome</b>!"
    },
    "toRecipients":[
        {
            "emailAddress":{
                "address":"postmaster@icewolf.ch"
            }
        }
    ]
}
"@
$Result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -Body $Body -ContentType $ContentType
$Result

###############################################################################
# Add Attachment to Mailbox Message (max 3MB)
# https://docs.microsoft.com/en-us/graph/api/message-post-attachments?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "postmaster@icewolf.ch"
$MessageID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQBGAAAAAADI11bk3aFKQJXy4z2GgQYRBwD4k93uZqwxSo0-0gbfaWPWAAAAr8HgAAD9DAdvUOIbRK2TMu1gBCF9AAORA6PVAAA="
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$MessageID/attachments"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$FolderID/messages/$MessageID/attachments"

$CurrentLocation = (Get-Location).path
$ContentByte = Get-Content -Path "$CurrentLocation\DemoAttachment.docx" -Encoding Byte

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
    "@odata.type": "#microsoft.graph.fileAttachment",
    "name": "DemoAttachment.docx",
    "contentBytes": "$ContentByte"
}
"@

$Result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -Body $Body -ContentType $ContentType
$Result

###############################################################################
# Delete  Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/message-delete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "Postmaster@icewolf.ch"
$MessageID = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$MessageID"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages/$MessageID"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "DELETE" -Uri $uri -Headers $Headers -ContentType $ContentType

###############################################################################
# Permanent Delete Mailbox Message
# https://learn.microsoft.com/en-us/graph/api/message-permanentdelete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "Postmaster@icewolf.ch"
$MessageID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQBGAAAAAADI11bk3aFKQJXy4z2GgQYRBwD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAD9DAdvUOIbRK2TMu1gBCF9AAaBvvhvAAA="
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$MessageID/permanentDelete"
$FolderID = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQAuAAAAAADI11bk3aFKQJXy4z2GgQYRAQD4k93uZqwxSo0-0gbfaWPWAAAAr8HVAAA="
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages/$MessageID/permanentDelete"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -ContentType $ContentType

###############################################################################
# SendMail
# https://docs.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.Send
#Delegated (personal Microsoft account)	Mail.Send
#Application	Mail.Send

$Mailbox = "postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/sendMail"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
    "message": {
        "subject": "Test mit Powershell",
        "body": {
            "contentType": "Text",
            "content": "Send a Mail with Powershell via Graph API."
        },
        "toRecipients": [
            {
                "emailAddress": {
                    "address": "a.bohren@icewolf.ch"
                }
            }
        ]
    }
}
"@
$Result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType

###############################################################################
# Use the Microsoft Search API to search Outlook messages
# https://docs.microsoft.com/en-us/graph/search-concept-messages
###############################################################################
# Users can search their own mailbox, but can't search delegated mailboxes

$URI = "https://graph.microsoft.com/v1.0/search/query"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$Body = @"
{
    "requests": [
    {
        "entityTypes": [
        "message"
        ],
        "query": {
        "queryString": "Swisscom"
        },
        "from": 0,
        "size": 25
    }
    ]
}
"@

$Result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType
$Result.value | Format-List
$Result.value.hitsContainers.hits

###############################################################################
#Get calendar
#https://docs.microsoft.com/en-us/graph/api/calendar-get?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.Read
#Delegated (personal Microsoft account)	Calendars.Read
#Application	Calendars.Read
#Group/Teams Calendar only works with Delegated work or School Account

$mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/Calendars"
$Calendars = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Calendars.Value | Format-List name,id

###############################################################################
#List Events
#https://docs.microsoft.com/en-us/graph/api/user-list-events?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.Read, Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.Read, Calendars.ReadWrite
#Application	Calendars.Read, Calendars.ReadWrite

$mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events"
Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Events = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Events | Get-Member

$Events.Value | Format-Table subject,start,end,location

#Loop through Results as long there is a odata.nextLink
if ($null -ne $Events.'@odata.nextLink') 
{
    do {
        $Uri = [uri]$Events.'@odata.nextLink';
        $Events = Invoke-RestMethod -Method GET -uri $uri -headers $headers
        $Events.Value | Format-Table subject,start,end,location
    } until ($null -eq $Events.'@odata.nextLink')
}


###############################################################################
# List Events on a Specific Date
###############################################################################
$mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendarView?startDateTime=2026-02-03T00:00:00&endDateTime=2026-02-04T00:00:00&`$select=subject,start,end,isAllDay,organizer"
#$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendarView?startDateTime=2026-02-03T00:00:00&endDateTime=2026-02-04T00:00:00&`$filter=startswith(Subject,'AVQ')&`$select=subject,start,end,isAllDay,organizer"
$Events = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Events.Value | Format-List subject,start,end,location

###############################################################################
 #Get Event by ID
###############################################################################
$mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$EventId = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQBGAAAAAADI11bk3aFKQJXy4z2GgQYRBwD4k93uZqwxSo0-0gbfaWPWAAAAr8HeAAD9DAdvUOIbRK2TMu1gBCF9AAcxzJpnAAA="
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events/$EventId"
$Events = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Events.Value | Format-list subject,start,end,location,id

###############################################################################
# Get Event by Subject
###############################################################################
$mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$subject = "AVQ 1844448053"
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events/?`$filter=startswith(Subject,'" + $Subject + "')"
$Events = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Events.Value | Format-list subject,start,end,location,id

###############################################################################
#Create Event
#https://docs.microsoft.com/en-us/graph/api/user-post-events?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.ReadWrite
#Application	Calendars.ReadWrite

$mailbox = "postmaster@icewolf.ch"
$headers = @{
    "Authorization" = "Bearer "+ $AccessToken;
    "Prefer" = 'outlook.timezone="W. Europe Standard Time"';
    "Content-type"  = "application/json"
}

#Timeformat: 2022-03-08T20:34:22
$StartDate = ((Get-Date).AddDays(+1)).GetDateTimeFormats("s")
$EndDate = ((Get-Date).AddHours(+1)).GetDateTimeFormats("s")

#Create JSON Object
$json = @"
{
    "subject":"Graph API Example",
    "body": {
        "contentType" : "HTML",
        "content" : "Write Graph API Powershell Script"
    },
    "start": {
        "dateTime" : "2022-03-08T12:00:00",
        "timeZone" : "W. Europe Standard Time"
    },
    "end": {
        "dateTime" : "2022-03-08T13:00:00",
        "timeZone" : "W. Europe Standard Time"
    },
    "location":{
        "displayName" : "HomeOffice"
    }
}
"@

$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events"
$Result = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $json
$Result | Format-List
$id = $Result.id

###############################################################################
#Get Event
#https://docs.microsoft.com/en-us/graph/api/event-get?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.Read
#Delegated (personal Microsoft account)	Calendars.Read
#Application	Calendars.Read

$id = "AAMkADExY2U2ZWY2LTI0YzEtNGQ3Mi1iODY0LTZmNzQ2MWQxOWJlYQBGAAAAAADI11bk3aFKQJXy4z2GgQYRBwD4k93uZqwxSo0-0gbfaWPWAAAAr8HeAAD9"
$Mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/events/$id"
$Result = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Result | Format-List start, end, subject, isorganizer, isReminderOn, reminderMinutesBeforeStart, attendees

###############################################################################
#Update event
#https://docs.microsoft.com/en-us/graph/api/group-update-event?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.ReadWrite
#Application	Calendars.ReadWrite

$id = "AQMkADU4NGU4M2ViLWM5NjctNGI0YS05ZmJhLTIyADdmYWI0MjRkYmQARgAAAzqJ2GWaRBxKv-EJWOBGbRAHAEZu88iLm85MjHqnrJ10b8oAAAIXkwAAAcb9AhgmYESSPal9iQNu6wAB0zikmgAAAA=="
$mailbox = "postmaster@icewolf.ch"
$headers = @{
    "Authorization" = "Bearer "+ $AccessToken;
    "Content-type"  = "application/json"
}

$json = @"
    {
        "subject" : "Graph API Example Update",
    },
    {
        "location":{
        "displayName" : "Office Bern"
        }
    }
"@

$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/events/$id"
$Result = Invoke-RestMethod -Method PATCH -Uri $uri -Headers $headers -Body $json
$Result

###############################################################################
# Delete event
# https://docs.microsoft.com/en-us/graph/api/event-delete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.ReadWrite
#Application	Calendars.ReadWrite

$id = "AQMkADU4NGU4M2ViLWM5NjctNGI0YS05ZmJhLTIyADdmYWI0MjRkYmQARgAAAzqJ2GWaRBxKv-EJWOBGbRAHAEZu88iLm85MjHqnrJ10b8oAAAIXkwAAAcb9AhgmYESSPal9iQNu6wAB0zikmgAAAA=="
$mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/events/$id"
Invoke-RestMethod -Method DELETE -uri $uri -headers $headers

###############################################################################
# Use the Microsoft Search API to search calendar events
# https://docs.microsoft.com/en-us/graph/search-concept-events
###############################################################################
# Use the Microsoft Search API to search for events in the signed-in user’s primary calendar. The user identity for the search is based on the auth token.

$URI = "https://graph.microsoft.com/v1.0/search/query"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$Body = @"
{
    "requests": [
    {
        "entityTypes": [
        "event"
        ],
        "query": {
        "queryString": "contoso"
        },
        "from": 0,
        "size": 25
    }
    ]
}
"@

$Result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType

###############################################################################
# List contactFolders
# https://docs.microsoft.com/en-us/graph/api/user-list-contactfolders?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$mailbox = "postmaster@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders"
$Result = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Result

###############################################################################
# List contacts
# https://docs.microsoft.com/en-us/graph/api/user-list-contacts?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "postmaster@icewolf.ch"
#$URI = "https://graph.microsoft.com/beta/users/$Mailbox/contacts"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers
$Result.value[0]

###############################################################################
# Create contact
# https://docs.microsoft.com/en-us/graph/api/user-post-contacts?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "postmaster@icewolf.ch"
$ContactFolderId = ""
#$URI = "https://graph.microsoft.com/beta/users/$Mailbox/contacts"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts"
#$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
    "givenName": "Pavel",
    "surname": "Bansky",
    "emailAddresses": [
    {
        "address": "pavelb@fabrikam.onmicrosoft.com",
        "name": "Pavel Bansky"
    }
    ],
    "businessPhones": [
    "+1 732 555 0102"
    ]
}
"@

$Result = Invoke-RestMethod -Method "POST" -uri $uri -headers $headers -Body $Body -ContentType $ContentType
$Result.value
$ContactID = $Result.id
$ContactID

###############################################################################
# Get contact
# https://docs.microsoft.com/en-us/graph/api/contact-get?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "postmaster@icewolf.ch"
$ContactID = ""
$ContactFolderId = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts/$ContactID"
#$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts/$ContactID"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$Result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers 


###############################################################################
# Update contact
# https://docs.microsoft.com/en-us/graph/api/contact-update?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "postmaster@icewolf.ch"
$ContactID = ""
$ContactFolderId = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts/$ContactID"
#$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts/$ContactID"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$Body = @"
{
    "homeAddress": {
        "street": "123 Some street",
        "city": "Seattle",
        "state": "WA",
        "postalCode": "98121"
    },
    "birthday": "1974-07-22"
}
"@

$Result = Invoke-RestMethod -Method "PATCH" -uri $uri -headers $headers -Body $Body -ContentType $ContentType
$Result

###############################################################################
# Delete contact
# https://docs.microsoft.com/en-us/graph/api/contact-delete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "postmaster@icewolf.ch"
$ContactID = ""
$ContactFolderId = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts/$ContactID"
#$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts/$ContactID"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$Result = Invoke-RestMethod -Method "DELETE" -uri $uri -headers $headers 
$Result


###############################################################################
# List ToDo lists
# https://docs.microsoft.com/en-us/graph/api/todo-list-lists?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Tasks.ReadWrite
#Delegated (personal Microsoft account)	Tasks.ReadWrite
#Application	Not supported

#$Mailbox = "a.bohren@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/me/todo/lists"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$Result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers 
$Result.value
$ToDoListID = $Result.value[0].id

###############################################################################
# List tasks
# https://docs.microsoft.com/en-us/graph/api/todotasklist-list-tasks?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Tasks.ReadWrite
#Delegated (personal Microsoft account)	Tasks.ReadWrite
#Application	Not supported

#$Mailbox = "a.bohren@icewolf.ch"
$ToDoListID = "AAMkADU4NGU4M2ViLWM5NjctNGI0YS05ZmJhLTIyN2ZhYjQyNGRiZAAuAAAAAAA6idhlmkQcSr-xCVjgRm0QAQAAxv0CGCZgRJI9qX2JA27rAAIdgHwoAAA="
$URI = "https://graph.microsoft.com/v1.0/me/todo/lists/$ToDoListID/tasks"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers
$Result