###############################################################################
# Graph API Calendar getShedule (Availabilit aka Free/Busy)
# https://docs.microsoft.com/en-us/graph/api/calendar-getschedule?view=graph-rest-1.0&tabs=http
# 06.06.2022 V1.0 - Initial Version - Andres Bohren
# App needs Application Permissions:
# - Calendars.Read (Only for the Mailbox where you make the Requests from - Limit with ApplicationAccessPolicy)
# - Schedule.Read.All
###############################################################################

#ApplicationAccessPolicy
Connect-ExchangeOnline
New-ApplicationAccessPolicy -AccessRight RestrictAccess -AppId b1fe3302-d057-4fe3-84ac-c507ecdb6d0d -PolicyScopeGroupId PostmasterGraphRestriction@icewolf.ch -Description "Restrict this app to members of this Group"
Get-ApplicationAccessPolicy -AppId b1fe3302-d057-4fe3-84ac-c507ecdb6d0d
Get-ApplicationAccessPolicy | Where-Object {$_.AppId -eq "b1fe3302-d057-4fe3-84ac-c507ecdb6d0d"}
Test-ApplicationAccessPolicy -AppId b1fe3302-d057-4fe3-84ac-c507ecdb6d0d -Identity postmaster@icewolf.ch
Test-ApplicationAccessPolicy -AppId b1fe3302-d057-4fe3-84ac-c507ecdb6d0d -Identity max.muster@icewolf.ch

#Change Calendarpermission
Get-MailboxFolderPermission -Identity max.muster@icewolf.ch:\Kalender
Set-MailboxFolderPermission -Identity max.muster@icewolf.ch:\Kalender -User Default -AccessRights AvailabilityOnly
Set-MailboxFolderPermission -Identity max.muster@icewolf.ch:\Kalender -User Default -AccessRights Reviewer
Set-MailboxFolderPermission -Identity max.muster@icewolf.ch:\Kalender -User Default -AccessRights Editor
Add-MailboxFolderPermission -Identity max.muster@icewolf.ch:\Kalender -User postmaster@icewolf.ch -AccessRights Reviewer

#Variables
$AppID = "b1fe3302-d057-4fe3-84ac-c507ecdb6d0d"
$Thumbprint = '4F1C474F862679EC35650824F73903041E1E5742'
$TenantId = "icewolfch.onmicrosoft.com"
$Certificate = Get-Item "Cert:\CurrentUser\My\$Thumbprint"

#Get AccessToken with MSAL Certificate Auth
Import-Module MSAL.PS
Clear-MsalTokenCache
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$Token = Get-MsalToken -ClientId $AppID -TenantId $TenantID -RedirectUri $RedirectUri -ClientCertificate $Certificate
$AccessToken = $Token.AccessToken

#Inspect the Access Token using JWTDetails PowerShell Module
Install-Module JWTDetails
Import-Module JWTDetails
Get-JWTDetails -Token $AccessToken 

#Get Availability (aka Free/Busy)
$From = "postmaster@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$From/calendar/getSchedule"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}

$Body = @{
	Schedules = @(
		"max.muster@icewolf.ch"		
	)
	StartTime = @{
		DateTime = "2022-06-06T06:00:00"
		TimeZone = "W. Europe Standard Time"
	}
	EndTime = @{
		DateTime = "2022-06-12T19:00:00"
		TimeZone = "W. Europe Standard Time"
	}
	AvailabilityViewInterval = 60
}
$jsonBody = $Body | ConvertTo-Json -Depth 4

$result = Invoke-RestMethod -Method "POST" -Uri $uri -Headers $Headers -ContentType $ContentType -Body $JsonBody
$Result.value.scheduleItems

