###############################################################################
# M365LicenseCheckV2
# V2.0 01.03.2022 - Initial Version - Andres Bohren
# https://blog.icewolf.ch/archive/2021/11/29/hinzufugen-und-entfernen-von-m365-lizenzen-mit-microsoft-graph-powershell.aspx
#
# Due to the high Permissions Restrict Exchange Access to Specific Mailboxes
# Restrict Access to Specific Mailboxes with ApplicationAccessPolicy
# https://blog.icewolf.ch/archive/2021/02/06/limit-microsoft-graph-access-to-specific-exchange-mailboxes.aspx
# New-ApplicationAccessPolicy -AccessRight RestrictAccess -AppId "33554333-f7a0-4d7e-9964-1bd5696ec8e4" -PolicyScopeGroupId "PostmasterGraphRestriction@icewolf.ch" -Description "Restrict this app to members of this Group"
# New-ApplicationAccessPolicy -AccessRight "RestrictAccess" -AppId "33554333-f7a0-4d7e-9964-1bd5696ec8e4" -PolicyScopeGroupId "05c4f6cf-e3e7-40a1-b3b0-f1eb680f78c9" -Description "Restrict this app to members of this Group"
#
# ApplicationAccessPolicy only Restricts the following Scopes
# -Mail.Read 
# -Mail.ReadWrite 
# -Mail.Send 
# -MailboxSettings.Read 
# -MailboxSettings.ReadWrite 
# -Calendars.Read 
# -Calendars.ReadWrite 
# -Contacts.Read 
# -Contacts.ReadWrite 
###############################################################################
#Needed Modules
###############################################################################
# -Microsoft.Graph.Authentication
# -Microsoft.Graph.Users.Action
# -Microsoft.Graph.Mail
# -Microsoft.Graph.Identity.Management
###############################################################################
#Needed Permissions
###############################################################################
#Application Permissions
# -Directory.Read.All
# -Mail.ReadWrite
# -Mail.Send
# -User.Read.All



###############################################################################
# Variables Azure Automation
###############################################################################
#Get Automation Connection / Certification
$Connection = Get-AutomationConnection -Name "AzureRunAsConnection"
$Cert = Get-AutomationCertificate -name "O365Powershell2"
$CertificateThumbprint = $Cert.ThumbPrint

#If you prefer to use AutomationVariables
#$TenantID = Get-AutomationVariable -Name "TenantId"

$AppID = "33554333-f7a0-4d7e-9964-1bd5696ec8e4" #AADLicense
Write-Output "AppID: $AppID"
Write-Output "TenantID: $($Connection.TenantId)"
Write-Output "CertificateThumbprint: $CertificateThumbprint"



###############################################################################
#Send Mail
###############################################################################
Write-Output "Sending Mail"
#HTML header with styles
$htmlbody="<html>
     <style>
      BODY{font-family: Arial; font-size: 10pt;}
	H1{font-size: 22px;}
	H2{font-size: 18px; padding-top: 10px;}
	H3{font-size: 16px; padding-top: 8px;}
    </style>
    <body>
     <h3>Title</h3>
     <p>Just a line of Text</p>
     </body>
     </html>"


$From = "postmaster@icewolf.ch"
$To = @"
	{
	"emailAddress":{
		"address":"a.bohren@icewolf.ch"
		}
	}
"@
$MessageBody = @{
	content = "$($htmlbody)"
	ContentType = 'html'
	}
$Subject = "Mail via Microsoft Graph"

# Create a draft message in the signed-in user's mailbox
$NewMessage = New-MgUserMessage -UserId $From -ToRecipients $To -Subject $Subject -Body $MessageBody
$NewMessage.ToRecipients.EmailAddress

# Send the message
Send-MgUserMessage -UserId $From -MessageId $NewMessage.Id  

###############################################################################
#Disconnect-MgGraph
###############################################################################
Write-Output "Disconnect-MgGraph"
Disconnect-MgGraph

