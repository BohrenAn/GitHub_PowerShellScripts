###############################################################################
# Create Azure AD Application with Microsoft.Graph PowerShell
# 01.12.2022 V0.1 - Initial Version - Andres Bohren
###############################################################################
#Install Module
Install-Module Microsoft.Graph.Authentication
Install-Module Microsoft.Graph.Applications

#Import Module
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Applications

###############################################################################
#Connect-MgGraph
#Connect to your Azure Active Directory with "Application Adminstrator" or "Global Administrator" Role
###############################################################################
Connect-MgGraph -Scopes "Application.Read.All","Application.ReadWrite.All","User.Read.All"
Get-MgContext

###############################################################################
#Create AAD Application
###############################################################################
$AppName =  "DemoApp"
$App = New-MgApplication -DisplayName $AppName 
$APPObjectID = $App.Id


###############################################################################
#List Applications
###############################################################################
Get-MgApplication
Get-MgApplication -ApplicationId $APPObjectID

###############################################################################
#Add additional Owner
#The User who created the Application is automatically the Owner
###############################################################################
$User = Get-MgUser -UserId "m.muster@domain.tld"
$ObjectId = $User.ID
$NewOwner = @{
	"@odata.id"= "https://graph.microsoft.com/v1.0/directoryObjects/{$ObjectId}"
	}
New-MgApplicationOwnerByRef -ApplicationId $APPObjectID -BodyParameter $NewOwner

###############################################################################
#Add a ClientSecret
###############################################################################
$passwordCred = @{
    "displayName" = "DemoClientSecret"
    "endDateTime" = (Get-Date).AddMonths(+12)
}
$ClientSecret2 = Add-MgApplicationPassword -ApplicationId $APPObjectID -PasswordCredential $passwordCred
$ClientSecret2
$ClientSecret2.SecretText

#Show ClientSecrets
$App = Get-MgApplication -ApplicationId $APPObjectID
$App.PasswordCredentials

###############################################################################
#Create a Self Signed Certificate
###############################################################################
#Create SelfSignedCertificate
$Subject = "DemoCert"
$NotAfter = (Get-Date).AddMonths(+24)
$Cert = New-SelfSignedCertificate -Subject $Subject -CertStoreLocation "Cert:\CurrentUser\My" -KeySpec Signature -NotAfter $Notafter -KeyExportPolicy Exportable
$ThumbPrint = $Cert.ThumbPrint

#View Certificates in the Current User Certificate Store
Get-ChildItem -Path cert:\CurrentUser\my\$ThumbPrint | Format-Table

#Export Certificate as Base64 (PEM Format)
$CurrentLocation = (Get-Location).path
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
Set-Content -Path "$CurrentLocation\$Subject-BASE64.cer" -Value $Value

###############################################################################
#Add Certificate to AzureAD App
###############################################################################
$CurrentLocation = (Get-Location).path
$CertPath = $CurrentLocation + "\" + $Subject + "-BASE64.cer"
$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate($CertPath)

#Get Certificate with Thumbprint from UserCertStore
$ThumbPrint = "07EFF3918F47995EB53B91848F69B5C0E78622FD"
$Cert = Get-ChildItem -Path cert:\CurrentUser\my\$ThumbPrint 

#Get Certificate with SubjectName from UserCertStore
$Subject = "CN=DemoCert"
$Cert = Get-ChildItem -Path cert:\CurrentUser\my\ | Where-Object {$_.Subject -eq "$Subject"}  


# Create a keyCredential (Certificate) for App
$keyCreds = @{ 
    Type = "AsymmetricX509Cert";
    Usage = "Verify";
    key = $cert.RawData
}
 
try {
   Update-MgApplication -ApplicationId $APPObjectID  -KeyCredentials $keyCreds
} catch {
   Write-Error $Error[0]
}

#Show Certificate of Azure AD Application
$App = Get-MgApplication -ApplicationId $APPObjectID
$App.KeyCredentials

###############################################################################
#Add App Permissions
###############################################################################
<#
All permissions and IDs
https://learn.microsoft.com/en-us/graph/permissions-reference#all-permissions-and-ids

Limiting application permissions to specific Exchange Online mailboxes (ApplicationAccessPolicy) https://docs.microsoft.com/en-us/graph/auth-limit-mailbox-access
Limit Microsoft Graph Access to specific Exchange Mailboxes (ApplicationAccessPolicy) https://blog.icewolf.ch/archive/2021/02/06/limit-microsoft-graph-access-to-specific-exchange-mailboxes.aspx

Works only for Exchange specific Permissions
- Calendars
- Contacts
- Mail
- Mailbox settings
#>

#Add Delegated Permission
#User.ReadBasic.All	Delegated	b340eb25-3456-403f-be2f-af7a0d370277
$params = @{
	RequiredResourceAccess = @(
		@{
			ResourceAppId = "00000003-0000-0000-c000-000000000000"
			ResourceAccess = @(
				@{
					Id = "b340eb25-3456-403f-be2f-af7a0d370277"
					Type = "Scope"
				}
			)
		}
	)
}
Update-MgApplication -ApplicationId $APPObjectID -BodyParameter $params

#Add Application Permission
#User.ReadBasic.All	Application	97235f07-e226-4f63-ace3-39588e11d3a1
$params = @{
	RequiredResourceAccess = @(
		@{
			ResourceAppId = "00000003-0000-0000-c000-000000000000"
			ResourceAccess = @(
				@{
					Id = "97235f07-e226-4f63-ace3-39588e11d3a1"
					Type = "Role"
				}
			)
		}
	)
}
Update-MgApplication -ApplicationId $APPObjectID -BodyParameter $params

#You can also add Application and Delegated Permissions (But you should not!)
#User.ReadBasic.All	Application	97235f07-e226-4f63-ace3-39588e11d3a1
#User.ReadBasic.All	Delegated	b340eb25-3456-403f-be2f-af7a0d370277
$params = @{
	RequiredResourceAccess = @(
		@{
			ResourceAppId = "00000003-0000-0000-c000-000000000000"
			ResourceAccess = @(
				@{
					Id = "b340eb25-3456-403f-be2f-af7a0d370277"
					Type = "Scope"
				},
				@{
					Id = "97235f07-e226-4f63-ace3-39588e11d3a1"
					Type = "Role"
				}
			)
		}
	)
}
Update-MgApplication -ApplicationId $APPObjectID -BodyParameter $params

#Show the App Permissions
$App = Get-MgApplication -ApplicationId $APPObjectID -Property * 
$App.RequiredResourceAccess | Format-List
$app.RequiredResourceAccess.resourceaccess

###############################################################################
#Grant Admin Consent
###############################################################################
#https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id={client-id}
$TenantID = ""
$AppID = ""
$URL = "https://login.microsoftonline.com/$TenantID/adminconsent?client_id=$AppID"
Start-Process $URL

###############################################################################
#Redirect URI
#If you need to add Redirect URI's.
###############################################################################
#Redirect URI
$App = Get-MgApplication -ApplicationId $APPObjectID -Property * 
$AppId = $App.AppId
$RedirectURI = @()
$RedirectURI += "https://login.microsoftonline.com/common/oauth2/nativeclient"
$RedirectURI += "msal" + $AppId + "://auth"
$RedirectURI += "https://localhost:3000"

$params = @{
	RedirectUris = @($RedirectURI)
}
Update-MgApplication -ApplicationId $APPObjectID -IsFallbackPublicClient -PublicClient $params

###############################################################################
#Remove the Application
###############################################################################
Remove-MgApplication -ApplicationId $APPObjectID