###############################################################################
# SimpleGraphSendMail.ps1
# A Simple Demo how to Send Mail via Microsoft Graph API
# 15.03.2022 V0.1 - Initial Draft - Andres Bohren
###############################################################################
#Needed Modules
# -MSAL.PS
###############################################################################
#Needed App Permissions
# - Application ->	Mail.Send

###############################################################################
# Limiting application permissions to specific Exchange Online mailboxes
# https://docs.microsoft.com/en-us/graph/auth-limit-mailbox-access
#
# Limit Microsoft Graph Access to specific Exchange Mailboxes
#https://blog.icewolf.ch/archive/2021/02/06/limit-microsoft-graph-access-to-specific-exchange-mailboxes.aspx
###############################################################################
#Get-AzureADGroup -SearchString PostmasterGraphRestriction | Format-Table DisplayName, ObjectId, SecurityEnabled, MailEnabled, Mail
#App: DelegatedMail c1a5903b-cd73-48fe-ac1f-e71bde968412
#New-ApplicationAccessPolicy -AccessRight RestrictAccess -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -PolicyScopeGroupId PostmasterGraphRestriction@icewolf.ch -Description "Restrict this app to members of this Group"
#Get-ApplicationAccessPolicy
#Test-ApplicationAccessPolicy -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -Identity postmaster@icewolf.ch
#Test-ApplicationAccessPolicy -AppId c1a5903b-cd73-48fe-ac1f-e71bde968412 -Identity SharedMBX@icewolf.ch

#Import PS Module
Import-Module MSAL.PS

###############################################################################
# Get AccessToken with MSAL
###############################################################################
#Variables
$TenantId = "icewolfch.onmicrosoft.com"
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$CertificateThumbprint = "4F1C474F862679EC35650824F73903041E1E5742" #O365Powershell2.cer
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$Scope = "https://graph.microsoft.com/.default" 

#Authenticate with Certificate
$Certificate = Get-ChildItem -Path cert:\CurrentUser\my\$CertificateThumbprint
$Token = Get-MsalToken -ClientId $AppID -ClientCertificate $Certificate -TenantId $TenantID -Scope $Scope -RedirectUri $RedirectUri
$AccessToken = $Token.AccessToken

###############################################################################
# Sends Mail via Microsoft Graph API
# https://docs.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.Send
#Delegated (personal Microsoft account)	Mail.Send
#Application	Mail.Send

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


$Mailbox = "postmaster@icewolf.ch"
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