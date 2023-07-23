###############################################################################
# Create Azure AD App for IMAP /SMTP Access to Shared Mailbox
# -Add Redirect URI > Mobile and Desktop Applications > MSAL
# -Add API Permissions > Microsoft Graph > Delegated > "IMAP.AccessAsUser.All","Mail.Send.Shared"
# 23.07.2023 - Andres Bohren
###############################################################################

###############################################################################
# Get AzureAD Application with Microsoft.Graph PowerShell
###############################################################################
Connect-MgGraph -Scopes 'Application.Read.All'
$AppName = "EXO_IMAP_Delegated"
$Filter = "DisplayName eq '" + $AppName + "'"
$ServicePrincipalDetails = Get-MgServicePrincipal -Filter "$Filter"
$ServicePrincipalDetails

###############################################################################
# Create Exchange Service Principal
###############################################################################
Connect-ExchangeOnline -ShowBanner:$false
New-ServicePrincipal -AppId $ServicePrincipalDetails.AppId -ServiceId $ServicePrincipalDetails.Id -DisplayName "EXO Serviceprincipal $($ServicePrincipalDetails.Displayname)"

###############################################################################
# CAS Mailbox
###############################################################################
$Mailbox = "SharedMBX@icewolf.ch"
Get-CASMailbox -Identity $Mailbox 
Set-CASMailbox -Identity $Mailbox -PopEnabled $false -ImapEnabled $true -SmtpClientAuthenticationDisabled $false
Get-CASMailbox -Identity $Mailbox


###############################################################################
#Full Access
###############################################################################
$Mailbox = "SharedMBX@icewolf.ch"
$User = "a.bohren@icewolf.ch"

#Add FullAccess Permission
Add-MailboxPermission -Identity $Mailbox -User $User -AccessRights FullAccess -AutoMapping $false

#Get FullAccess Permissions
Get-MailboxPermission  -Identity $Mailbox | Where-Object { ($_.AccessRights -eq "FullAccess") -and ($_.IsInherited -eq $false) -and -not ($_.User -like "NT AUTHORITY\SELF") } | Format-Table -AutoSize


###############################################################################
# Send As
###############################################################################
$Mailbox = "SharedMBX@icewolf.ch"
$Trustee = "a.bohren@icewolf.ch"

#Add SendAs Permissions
Add-RecipientPermission -Identity $Mailbox -Trustee $Trustee -AccessRights SendAs

#Get SendAs Permissions
Get-RecipientPermission  -Identity $Mailbox | Where-Object { ($_.AccessRights -eq "SendAs") -and ($_.IsInherited -eq $false) -and -not ($_.Trustee -like "NT AUTHORITY\SELF") } | Format-Table -AutoSize

###############################################################################
# Test Token with MSAL and JWTDetails
# Install-Module MSAL.PS
# Install-Module JWTDetails
###############################################################################
$AppID = "e9d3d08b-d477-4688-b972-8cb06eefe439"
$TenantID = "icewolfch.onmicrosoft.com"
$RedirectURI = "msale9d3d08b-d477-4688-b972-8cb06eefe439://auth"
Clear-MsalTokenCache
$Scopes = @("IMAP.AccessAsUser.All","Mail.Send.Shared")
$Token = Get-MsalToken -Interactive -Scopes $Scopes -TenantID $TenantID -ClientId $AppID -RedirectURI $RedirectURI
$AccessToken = $Token.AccessToken
Get-JWTDetails -token $AccessToken


###############################################################################
# Test Access
# OAuth2 IMAP Test Tool
# https://github.com/DanijelkMSFT/ThisandThat/blob/main/Get-IMAPAccessToken.ps1
###############################################################################
Clear-MsalTokenCache
$AppID = "e9d3d08b-d477-4688-b972-8cb06eefe439" #EXO_IMAP_Delegated
$TenantID = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$RedirectURI = "msale9d3d08b-d477-4688-b972-8cb06eefe439://auth"
.\Get-IMAPAccessToken.ps1  -tenantID $TenantID -clientId $AppID  -redirectUri $RedirectURI -LoginHint "a.bohren@icewolf.ch" -SharedMailbox "sharedmbx@icewolf.ch"

###############################################################################
# Sends Mail via Microsoft Graph API
# https://docs.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.Send
#Delegated (personal Microsoft account)	Mail.Send

#Create HTML Body
[string]$body = @"
<html>
	<head>
		<style>
		p {
			text-align: Left; 
			color: green;
			font-size: 12px;
			font-family: Arial
		}

		table, th, td {
			border: 1px solid;
			font-size: 12px;
			font-family: Arial
		}
		</style>
	</head>
<body>
	<h3>HTML Header</h3>
	<p>the quick brown fox jumps over the lazy dog</p>
</body>
</html>
"@


$Mailbox = "sharedmbx@icewolf.ch"
$URI = "https://graph.microsoft.com/v1.0/users/$Mailbox/sendMail"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
	"message": {
		"subject": "Microsoft Graph API Mail DEMO",
		"body": {
			"contentType": "HTML",
			"content": "$Body"
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

#Send Actual Mail
$result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType
If ($null -ne $result)
{
	Write-Host "Mail has been sucessufully sent"
}