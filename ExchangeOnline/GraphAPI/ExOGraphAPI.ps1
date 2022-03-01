###############################################################################
# DEMO of Mailhandling with GraphAPI (Mail / Calendar / Personal contacts)
# 01.03.2022 V0.1 - Initial Draft - Andres Bohren
#
#
###############################################################################


###############################################################################
#Clear Tokencache
Clear-MsalTokenCache
###############################################################################

###############################################################################
# Get AccessToken with MSAL
###############################################################################
Import-Module MSAL.PS
$TenantId = "icewolfch.onmicrosoft.com"
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$ClientSecret = ConvertTo-SecureString "YourClientSecret" -AsPlainText -Force
$CertificateThumbprint = "4F1C474F862679EC35650824F73903041E1E5742" #O365Powershell2.cer

$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$Scope = "https://graph.microsoft.com/.default" 
$Token = Get-MsalToken -ClientId $AppID -ClientSecret $ClientSecret -TenantId $TenantID -Scope $Scope -RedirectUri $RedirectUri
$AccessToken = $Token.AccessToken

###############################################################################
# Get AccessToken with Invoke-RestMethod
###############################################################################
#Variables
$ClientID = "9a8d72df-686a-496c-bc5e-a147d813abd1"
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
$result = Invoke-RestMethod -Method POST -uri $authority -Body $body
$AccessToken = $result.access_token


###############################################################################
# List Mailbox Folders
# https://docs.microsoft.com/en-us/graph/api/user-list-mailfolders?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Application	Mail.ReadBasic.All, Mail.Read, Mail.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/?includeHiddenFolders=true"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType

###############################################################################
# List Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/user-list-messages?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Application	Mail.ReadBasic.All, Mail.Read, Mail.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType

###############################################################################
# Create Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/user-post-messages?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
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

###############################################################################
# Add Attachment to Mailbox Message (max 3MB)
# https://docs.microsoft.com/en-us/graph/api/message-post-attachments?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
$MessageID = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$MessageID/attachments"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$FolderID/messages/$MessageID/attachments"

$ContentByte = $Get-Content -Path "C:\GIT_WorkingDir\GitHub_PowerShellScripts\ExchangeOnline\GraphAPI\DemoAttachment.docx" -AsByteStream

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
  "@odata.type": "#microsoft.graph.fileAttachment",
  "name": "smile",
  "contentBytes": "$ContentByte"
}
"@

$result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -Body $Body -ContentType $ContentType



###############################################################################
# Delete  Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/message-delete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
$MessageID = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/messages/$MessageID"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$FolderID/messages/$MessageID"

$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$result = Invoke-RestMethod -Method "DELETE" -Uri $uri -Headers $Headers -ContentType $ContentType

###############################################################################
# Send As User
###############################################################################
$URI = "https://graph.microsoft.com/v1.0/users/a.bohren@icewolf.ch/sendMail"
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
                    "address": "postmaster@icewolf.ch"
                }
            }
        ]
    }
}
"@
$result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType

###############################################################################
# Send As User
###############################################################################
$URI = "https://graph.microsoft.com/v1.0/users/m.bohren@icewolf.ch/sendMail"
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
# Send As Shared MBX
###############################################################################
$URI = "https://graph.microsoft.com/v1.0/users/postmaster@icewolf.ch/sendMail"
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
#Get calendar
#https://docs.microsoft.com/en-us/graph/api/calendar-get?view=graph-rest-1.0&tabs=http
###############################################################################

$mailbox = "a.bohren@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/Calendars"
$Calendars = Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Calendars.Value | Format-List name,id

###############################################################################
#List Events
#https://docs.microsoft.com/en-us/graph/api/user-list-events?view=graph-rest-1.0&tabs=http
###############################################################################
$mailbox = "a.bohren@icewolf.ch"
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

$mailbox = "a.bohren@icewolf.ch"
$headers = @{
 "Authorization" = "Bearer "+ $AccessToken;
 "Prefer" = 'outlook.timezone="W. Europe Standard Time"';
 "Content-type"  = "application/json"
}

#Create JSON Object
$json = @"
{
  "subject":"Graph API Example",
  "body": {
    "contentType" : "HTML",
    "content" : "Write Graph API Powershell Script"
  },
  "start": {
      "dateTime" : "2020-04-30T07:00:00",
      "timeZone" : "W. Europe Standard Time"
  },
  "end": {
      "dateTime" : "2020-04-30T08:00:00",
      "timeZone" : "W. Europe Standard Time"
  },
  "location":{
      "displayName" : "HomeOffice"
  }
}
"@

$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events"
Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $json

###############################################################################
#Get Event
#https://docs.microsoft.com/en-us/graph/api/event-get?view=graph-rest-1.0&tabs=http
###############################################################################
$id = "AQMkADU4NGU4M2ViLWM5NjctNGI0YS05ZmJhLTIyADdmYWI0MjRkYmQARgAAAzqJ2GWaRBxKv-EJWOBGbRAHAEZu88iLm85MjHqnrJ10b8oAAAIXkwAAAcb9AhgmYESSPal9iQNu6wAB0zikmgAAAA=="
$mailbox = "a.bohren@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events/$id"
Invoke-RestMethod -Method GET -uri $uri -headers $headers
$Events = Invoke-RestMethod -Method GET -uri $uri -headers $headers

###############################################################################
#Update event
#https://docs.microsoft.com/en-us/graph/api/group-update-event?view=graph-rest-1.0&tabs=http
###############################################################################
$id = "AQMkADU4NGU4M2ViLWM5NjctNGI0YS05ZmJhLTIyADdmYWI0MjRkYmQARgAAAzqJ2GWaRBxKv-EJWOBGbRAHAEZu88iLm85MjHqnrJ10b8oAAAIXkwAAAcb9AhgmYESSPal9iQNu6wAB0zikmgAAAA=="
$mailbox = "a.bohren@icewolf.ch"
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

$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events/$id"
Invoke-RestMethod -Method PATCH -Uri $uri -Headers $headers -Body $json

###############################################################################
# Delete event
# https://docs.microsoft.com/en-us/graph/api/event-delete?view=graph-rest-1.0&tabs=http
###############################################################################

$id = "AQMkADU4NGU4M2ViLWM5NjctNGI0YS05ZmJhLTIyADdmYWI0MjRkYmQARgAAAzqJ2GWaRBxKv-EJWOBGbRAHAEZu88iLm85MjHqnrJ10b8oAAAIXkwAAAcb9AhgmYESSPal9iQNu6wAB0zikmgAAAA=="
$mailbox = "a.bohren@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/calendar/events/$id"
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

$mailbox = "a.bohren@icewolf.ch"
$headers = @{"Authorization" = "Bearer "+ $AccessToken}
$uri = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders"
$ContactFolders = Invoke-RestMethod -Method GET -uri $uri -headers $headers


###############################################################################
# Create contact
# https://docs.microsoft.com/en-us/graph/api/user-post-contacts?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
$ContactFolderId = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts"
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

$result = Invoke-RestMethod -Method "POST" -uri $uri -headers $headers -Body $Body


###############################################################################
# Get contact
# https://docs.microsoft.com/en-us/graph/api/contact-get?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
$ContactID = ""
$ContactFolderId = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts/$ContactID"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts/$ContactID"
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

$Mailbox = "a.bohren@icewolf.ch"
$ContactID = ""
$ContactFolderId = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts/$ContactID"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts/$ContactID"
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

$result = Invoke-RestMethod -Method "PATCH" -uri $uri -headers $headers -Body $Body


###############################################################################
# Delete contact
# https://docs.microsoft.com/en-us/graph/api/contact-delete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Contacts.Read, Contacts.ReadWrite
#Delegated (personal Microsoft account)	Contacts.Read, Contacts.ReadWrite
#Application	Contacts.Read, Contacts.ReadWrite

$Mailbox = "a.bohren@icewolf.ch"
$ContactID = ""
$ContactFolderId = ""
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contacts/$ContactID"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/contactFolders/$ContactFolderId/Contacts/$ContactID"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$result = Invoke-RestMethod -Method "DELETE" -uri $uri -headers $headers 