###############################################################################
# https://docs.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth#use-client-credentials-grant-flow-to-authenticate-imap-and-pop-connections
# https://github.com/DanijelkMSFT/ThisandThat/blob/main/Get-IMAPAccessToken.ps1
# Initial Version - 20.12.2022
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


###############################################################################
# Get AzureAD Application with Microsoft.Graph PowerShell
###############################################################################
Connect-MgGraph -Scopes 'Application.Read.All'
$ServicePrincipalDetails = Get-MgServicePrincipal -Filter "DisplayName eq 'DemoEXO-POP3-IMAP'"
$ServicePrincipalDetails

###############################################################################
# Create Exchange Service Principal
###############################################################################
Connect-ExchangeOnline
New-ServicePrincipal -AppId $ServicePrincipalDetails.AppId -ServiceId $ServicePrincipalDetails.Id -DisplayName "EXO Serviceprincipal $($ServicePrincipalDetails.Displayname)"

###############################################################################
# CAS Mailbox 
###############################################################################
Get-CASMailbox -Identity m.muster@icewolf.ch | Format-List imap*
Set-CASMailbox -Identity m.muster@icewolf.ch -PopEnabled $true -ImapEnabled $true

###############################################################################
#Full Access
###############################################################################
$Mailbox = "m.muster@icewolf.ch"
$SericePrincipal = "EXO Serviceprincipal DemoEXO-POP3-IMAP"
Add-MailboxPermission -Identity $Mailbox -User $SericePrincipal -AccessRights FullAccess -AutoMapping $false

$Mailbox = "m.muster@icewolf.ch"
Get-MailboxPermission  -Identity $Mailbox | Where-Object { ($_.AccessRights -eq "FullAccess") -and ($_.IsInherited -eq $false) -and -not ($_.User -like "NT AUTHORITY\SELF") } | ft -AutoSize

###############################################################################
# Get Access Token with MSAL
###############################################################################
Import-Module MSAL.PS

$AppID = "3bf0cf36-87bf-47a9-927b-0ef9df7cf146"
$TenantID = "icewolfch.onmicrosoft.com" 
$ClientSecret = ConvertTo-SecureString "YourClientSecret" -AsPlainText -Force
$Scope = "https://outlook.office.com/.default"

Clear-MsalTokenCache
$Token = Get-MSALToken -ClientId $AppID -ClientSecret $ClientSecret -TenantId $TenantID -Scope $Scope
$AccessToken = $Token.AccessToken

###############################################################################
# connecting to Office 365 IMAP Service
###############################################################################
Write-Host "Connect to Office 365 IMAP Service." -ForegroundColor DarkGreen
$ComputerName = "Outlook.office365.com"
$Port = "993"
    try {
        $TCPConnection = New-Object System.Net.Sockets.Tcpclient($($ComputerName), $Port)
        $TCPStream = $TCPConnection.GetStream()
        try {
            $SSLStream  = New-Object System.Net.Security.SslStream($TCPStream)
            $SSLStream.ReadTimeout = 5000
            $SSLStream.WriteTimeout = 5000
            $CheckCertRevocationStatus = $true
            $SSLStream.AuthenticateAsClient($ComputerName,$null,[System.Security.Authentication.SslProtocols]::Tls12,$CheckCertRevocationStatus)
        }
        catch  {
            Write-Host "Ran into an exception while negotating SSL connection. Exiting." -ForegroundColor Red
            $_.Exception.Message
            break
        }
    }
    catch  {
    Write-Host "Ran into an exception while opening TCP connection. Exiting." -ForegroundColor Red
    $_.Exception.Message
    break
    }   

# continue if connection was successfully established
$SSLstreamReader = new-object System.IO.StreamReader($sslStream)
$SSLstreamWriter = new-object System.IO.StreamWriter($sslStream)
$SSLstreamWriter.AutoFlush = $true
$SSLstreamReader.ReadLine()

###############################################################################
# Send "C01 CAPABILITY"
###############################################################################
Write-Host "C01 CAPABILITY" -ForegroundColor "Cyan"
$Text = "C01 CAPABILITY"
$SSLstreamWriter.WriteLine($Text)
$ResponseStr = $SSLstreamReader.ReadLine()
Write-Host "$ResponseStr" -ForegroundColor "Cyan"

#Wait for "C01 OK CAPABILITY completed"
$ResponseStr = $SSLstreamReader.ReadLine()
Write-Host "$ResponseStr" -ForegroundColor "Cyan"

###############################################################################
# Build Login
###############################################################################
$UserName = "m.muster@icewolf.ch"
#$Text = "user=test@contoso.onmicrosoft.com^Aauth=Bearer EwBAAl3BAAUFFpUAo7J3Ve0bjLBWZWCclRC3EoAA^A^A"
$Text = "user=" + $UserName + "$([char]0x01)auth=Bearer " + $accessToken + "$([char]0x01)$([char]0x01)"
$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
$EncodedText =[Convert]::ToBase64String($Bytes)

$Login = "C02 AUTHENTICATE XOAUTH2 $EncodedText"
#$Login
#$Login | clip

###############################################################################
# Authenticate with XOAUTH2
###############################################################################
Write-Host "Authenticate using XOAuth2" -ForegroundColor "Cyan"
$SSLstreamWriter.WriteLine($Login)
$ResponseStr = $SSLstreamReader.ReadLine()
Write-Host "$ResponseStr" -ForegroundColor "Cyan"

###############################################################################
# List
###############################################################################
$Text = 'C03 LIST "" *'
$SSLstreamWriter.WriteLine($Text)
while ($ResponseStr -notmatch "LIST completed") 
{
	$ResponseStr = $SSLstreamReader.ReadLine()
	Write-Host "$ResponseStr" -ForegroundColor "Cyan"
}

###############################################################################
# Close
###############################################################################
Write-Host "C04 LOGOUT" -ForegroundColor "Cyan"
$Text = 'C04 LOGOUT'
$SSLstreamWriter.WriteLine($Text)
$ResponseStr = $SSLstreamReader.ReadLine()
Write-Host "$ResponseStr" -ForegroundColor "Cyan"

###############################################################################
# Cleanup
###############################################################################
$SSLstreamWriter.Close()
$SSLstreamReader.Close()
$SSLStream.Close()


###############################################################################
# Test with OpenSSL
###############################################################################
<#
cd C:\Program Files\Git\usr\bin
openssl.exe s_client -connect outlook.office365.com:993 -crlf -quiet

C: C01 CAPABILITY
S: * CAPABILITY … AUTH=XOAUTH2
S: C01 OK Completed
C: C02 AUTHENTICATE XOAUTH2 dXNlcj1zb21ldXNlckBleGFtcGxlLmNvbQFhdXRoPUJlYXJlciB5YTI5LnZGOWRmdDRxbVRjMk52YjNSbGNrQmhkSFJoZG1semRHRXVZMjl0Q2cBAQ==
S: C02 OK AUTHENTICATE completed.
C: C03 LIST "" *
S: C03 OK LIST completed
C: C04 Logout
S: C04 OK LOGOUT completed
#>