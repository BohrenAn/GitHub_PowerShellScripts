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
Get-AzureADGroup -SearchString PostmasterGraphRestriction | Format-Table DisplayName, ObjectId, SecurityEnabled, MailEnabled, Mail
#App: DelegatedMail c1a5903b-cd73-48fe-ac1f-e71bde968412
New-ApplicationAccessPolicy -AccessRight RestrictAccess -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -PolicyScopeGroupId PostmasterGraphRestriction@icewolf.ch -Description "Restrict this app to members of this Group"
Get-ApplicationAccessPolicy
Get-ApplicationAccessPolicy | Where-Object {$_.Appid -eq "c1a5903b-cd73-48fe-ac1f-e71bde968412"}
Test-ApplicationAccessPolicy -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -Identity postmaster@icewolf.ch
Test-ApplicationAccessPolicy -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -Identity SharedMBX@icewolf.ch

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
#Clear Tokencache
Clear-MsalTokenCache
###############################################################################

###############################################################################
# Get AccessToken with MSAL
###############################################################################
#Install-Module MSAL.PS

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
$result = Invoke-RestMethod -Method POST -uri $authority -Body $body
$AccessToken = $result.access_token


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
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$result.value | Format-Table displayName, id

###############################################################################
# List Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/user-list-messages?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Application	Mail.ReadBasic.All, Mail.Read, Mail.ReadWrite

$Mailbox = "Postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType
$result.value[0] | Format-List
$result.value | Format-List receivedDateTime, subject, hasAttachments, importance, internetMessageId,isRead


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
$result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -Body $Body -ContentType $ContentType
$result

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

$ContentByte = Get-Content -Path "C:\GIT_WorkingDir\GitHub_PowerShellScripts\ExchangeOnline\GraphAPI\DemoAttachment.docx" -Encoding Byte

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
  "@odata.type": "#microsoft.graph.fileAttachment",
  "name": "DemoAttachment.docx",
  "contentBytes": "$ContentByte"
}
"@

$result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -Body $Body -ContentType $ContentType
$result


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
$result = Invoke-RestMethod -Method "DELETE" -Uri $uri -Headers $Headers -ContentType $ContentType

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
$result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType

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

$result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType
$result.value | Format-List
$result.value.hitsContainers.hits

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
$id = $result.id

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
$result | Format-List start, end, subject, isorganizer, isReminderOn, reminderMinutesBeforeStart, attendees

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
$result

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

$result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType

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
$result

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
$result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers
$result.value[0]

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

$result = Invoke-RestMethod -Method "POST" -uri $uri -headers $headers -Body $Body -ContentType $ContentType
$result.value
$ContactID = $result.id
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

$result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers 


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

$result = Invoke-RestMethod -Method "PATCH" -uri $uri -headers $headers -Body $Body -ContentType $ContentType
$result

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

$result = Invoke-RestMethod -Method "DELETE" -uri $uri -headers $headers 
$result


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

$result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers 
$result.value
$ToDoListID = $result.value[0].id

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
$result = Invoke-RestMethod -Method "GET" -uri $uri -headers $headers
$result