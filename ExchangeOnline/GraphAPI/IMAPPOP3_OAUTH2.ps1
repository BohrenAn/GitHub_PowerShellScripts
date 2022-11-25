###############################################################################
# https://docs.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth#use-client-credentials-grant-flow-to-authenticate-imap-and-pop-connections
# https://github.com/DanijelkMSFT/ThisandThat/blob/main/Get-IMAPAccessToken.ps1
# Work in Progress...
###############################################################################
#Office 365 Exchange Online
#- IMAP.AccessAsApp
#- POP.AccessAsApp
#IMAP	https://outlook.office.com/IMAP.AccessAsUser.All
#POP	https://outlook.office.com/POP.AccessAsUser.All
#SMTP AUTH	https://outlook.office.com/SMTP.Send

#Manifest
<#
"requiredResourceAccess": [
		{
			"resourceAppId": "00000002-0000-0ff1-ce00-000000000000",
			"resourceAccess": [
				{
					"id": "cb842b43-da6e-4506-86fe-bb12199c656d",
					"type": "Role"
				},
				{
					"id": "5e5addcd-3e8d-4e90-baf5-964efab2b20a",
					"type": "Role"
				}
			]
		}
	],
#>

Get-CASMailbox -Identity a.bohren@icewolf.ch | Format-List imap*
#Set-CASMailbox -Identity a.bohren@icewolf.ch -ImapEnabled $true

$TenantID = "icewolfch.onmicrosoft.com" 
$AppID = "3bf0cf36-87bf-47a9-927b-0ef9df7cf146"
$AppObjectID = "fa0c3777-399d-41f4-ac98-d928ef19960b"
New-ServicePrincipal -AppId $AppID -ServiceId $AppObjectId -Organization $TenantID
Get-ServicePrincipal -Organization $TenantID | Format-List

$SericePrincipalID = "fa0c3777-399d-41f4-ac98-d928ef19960b"
Add-MailboxPermission -Identity "sharedmbx@icewolf.ch" -User $SericePrincipalID -AccessRights FullAccess


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AppID = "3bf0cf36-87bf-47a9-927b-0ef9df7cf146"
$TenantID = "icewolfch.onmicrosoft.com" 
$ClientSecret = ConvertTo-SecureString "" -AsPlainText -Force
$ClientSecret = "" 
$Scope = "https://outlook.office.com/.default"
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"


#Testing
.\Get-IMAPAccessToken.ps1 -tenantID $TenantID -clientId $AppID -clientsecret $ClientSecret -targetMailbox "sharedmbx@icewolf.ch"


###############################################################################
# Get Access Token
###############################################################################

Import-Module MSAL.PS
Clear-MsalTokenCache
$Token = Get-MSALToken -ClientId $AppID -ClientSecret $ClientSecret -TenantId $TenantID -Scope $Scope
#$Token = Get-MSALToken -ClientId $AppID -ClientSecret $ClientSecret -TenantId $TenantID -Interactive
#$Token = Get-MSALToken -ClientId $AppID  -TenantId $TenantID -Interactive -RedirectUri $RedirectUri -Scope $Scope
$AccessToken = $Token.AccessToken
$AccessToken | clip


$UserName = "Sharedmbx@icewolf.ch"
#Base64 Encode
$Text = "user=" + $userName + "^Aauth=Bearer " + $accessToken + "^A^A"
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
$EncodedText =[Convert]::ToBase64String($Bytes)
$EncodedText

#DECODE
$DecodedText = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedText))
$DecodedText

#Create Login
$Login = "C02 AUTHENTICATE XOAUTH2 $EncodedText"
$Login
$Login | clip

C: C01 CAPABILITY
S: * CAPABILITY … AUTH=XOAUTH2
S: C01 OK Completed
C: A01 AUTHENTICATE XOAUTH2 
S: A01 OK AUTHENTICATE completed.

#Connect
$ServerName = "outlook.office365.com"
$Port = "993"
Write-Host("Connect $ServerName $Port") -ForegroundColor Green
$socket = new-object System.Net.Sockets.TcpClient($ServerName, $Port)
$stream = $socket.GetStream()
$streamWriter = new-object System.IO.StreamWriter($stream)
$streamReader = new-object System.IO.StreamReader($stream)
$stream.ReadTimeout = 5000
$stream.WriteTimeout = 5000  
$streamWriter.AutoFlush = $true
$sslStream = New-Object System.Net.Security.SslStream($stream)
$sslStream.ReadTimeout = 5000
$sslStream.WriteTimeout = 5000       
$ConnectResponse = $streamReader.ReadLine();
Write-Host($ConnectResponse)
if(!$ConnectResponse.StartsWith("220")){
    throw "Error connecting to the SMTP Server"
}

openssl s_client -connect outlook.office365.com:993 -crlf 
C01 CAPABILITY
