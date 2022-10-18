###############################################################################
# How to Start with Microsoft.Graph PowerShell Modules
# V1.0 - Initial Version - Andres Bohren
###############################################################################
#Microsoft Graph PowerShell overview
#https://docs.microsoft.com/en-us/powershell/microsoftgraph/overview?view=graph-powershell-1.0

#Find Azure AD and MSOnline cmdlets in Microsoft Graph PowerShell
#https://docs.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map?view=graph-powershell-1.0

#Install Module
Install-Module MicrosoftGraph

#List all Modules
Get-Module Microsoft.Graph* -ListAvailable
Get-InstalledModule Microsoft.Graph*

###############################################################################
# CleanupGraphModules.ps1
# Instead of Updating the Microsoft.Graph Module use this Scriot
###############################################################################
https://github.com/BohrenAn/GitHub_PowerShellScripts/blob/main/ExchangeOnline/GraphAPI/CleanupGraphModules.ps1

#Run Script directly from GitHub
$ScriptFromGitHub = Invoke-WebRequest "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/ExchangeOnline/GraphAPI/CleanupGraphModules.ps1"
Invoke-Expression $($ScriptFromGitHub.Content)


###############################################################################
# Diffrent Logon Types
###############################################################################

#Interactive
Connect-MgGraph
Connect-MgGraph -Scopes "User.Read.All, Group.Read.All"
Disconnect-MgGraph

#Delegated
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$TenantId = "icewolfch.onmicrosoft.com"
Connect-MgGraph -AppId $AppID -TenantId $TenantId
Disconnect-MgGraph

#DeviceCode
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$TenantId = "icewolfch.onmicrosoft.com"
Connect-MgGraph -AppId $AppID -TenantId $TenantId -DeviceCode
Disconnect-MgGraph

#Connect with Certificate Thumbprint
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$CertificateThumbprint = "4F1C474F862679EC35650824F73903041E1E5742" #O365Powershell2.cer
$TenantId = "icewolfch.onmicrosoft.com"
Connect-MgGraph -AppId $AppID -CertificateThumbprint $CertificateThumbprint -TenantId $TenantId
Disconnect-MgGraph

#Connect with Certificate
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$Thumbprint = '4F1C474F862679EC35650824F73903041E1E5742'
$Certificate = Get-Item "Cert:\CurrentUser\My\$Thumbprint"
$TenantId = "icewolfch.onmicrosoft.com"
Connect-MgGraph -AppId $AppID -Certificate $Certificate -TenantId $TenantId
Disconnect-MgGraph

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
Export-Certificate -Filepath "C:\Git_WorkingDir\$Subject-DER.cer" -cert $Cert -type CERT -NoClobber 
Get-ChildItem -Path cert:\CurrentUser\my\$ThumbPrint | Export-Certificate -FilePath "C:\Git_WorkingDir\$Subject-DER.cer"
Get-ChildItem -Path cert:\CurrentUser\my\ | Where-Object {$_.Subject -eq "CN=$Subject"} | Export-Certificate -FilePath "C:\Git_WorkingDir\$Subject-DER.cer"

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
Set-Content -Path "C:\Git_WorkingDir\$Subject-BASE64.cer" -Value $Value

###############################################################################
#Export PFX Certificate
#https://docs.microsoft.com/en-us/powershell/module/pki/export-pfxcertificate?view=windowsserver2022-ps
###############################################################################
$PFXPassword = ConvertTo-SecureString -String "SecretPa$$word!" -Force -AsPlainText
$Cert = Get-ChildItem -Path cert:\CurrentUser\my\$ThumbPrint 
$Cert = Get-ChildItem -Path cert:\CurrentUser\my\ | Where-Object {$_.Subject -eq "CN=$Subject"}
Export-PfxCertificate -Cert $cert -FilePath "C:\Git_WorkingDir\$Subject.pfx" -Password $PFXPassword

###############################################################################
# Access Token with MSAL.PS
###############################################################################
#MSAL.PS
Install-Module MSAL.PS
Import-Module MSAL.PS
Clear-MsalTokenCache
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$Thumbprint = '4F1C474F862679EC35650824F73903041E1E5742'
$Certificate = Get-Item "Cert:\CurrentUser\My\$Thumbprint"
$TenantId = "icewolfch.onmicrosoft.com"
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
##Certificate
$Token = Get-MsalToken -ClientId $AppID -TenantId $TenantID -RedirectUri $RedirectUri -ClientCertificate $Certificate  -ErrorAction SilentlyContinue

##Interactive
$Token = Get-MsalToken -ClientId $AppID -TenantId $TenantID -RedirectUri $RedirectUri -ErrorAction SilentlyContinue

##DeviceCode
$Token = Get-MsalToken -ClientId $AppID -TenantId $TenantID -RedirectUri $RedirectUri -DeviceCode  -ErrorAction SilentlyContinue

$AccessToken = $Token.AccessToken
$AccessToken

Connect-MgGraph -AccessToken $AccessToken

###############################################################################
#JWTDeatils
###############################################################################
#Check Token in Browser
https://jwt.ms/

#Check Token with JWTDetails Module 
Install-Module JWTDetails
Import-Module JWTDetails
Get-JWTDetails -token $AccessToken

# Using your own access token.
Connect-MgGraph -AccessToken $AccessToken
Disconnect-MgGraph

###############################################################################
#Simple Commands 
###############################################################################
Select-MgProfile -Name "beta"
Get-MgContext
Get-MgUser -UserId "m.muster@icewolf.ch"
Get-MgUser -UserId "ff18c35d-8cd9-45ce-b4e3-7e7abe13ff4e"
Get-MgGroup
Get-MgGroup -Filter "displayName eq 'PostmasterGraphRestriction'"
Get-MgGroupMember -GroupId "05c4f6cf-e3e7-40a1-b3b0-f1eb680f78c9"

###############################################################################
# Find Azure AD and MSOnline cmdlets in Microsoft Graph PowerShell
# https://learn.microsoft.com/en-us/powershell/microsoftgraph/azuread-msoline-cmdlet-map?view=graph-powershell-1.0
###############################################################################

###############################################################################
# Microsoft Graph permissions reference
# https://learn.microsoft.com/en-us/graph/permissions-reference
###############################################################################

###############################################################################
# Use query parameters to customize responses
# https://docs.microsoft.com/en-us/graph/query-parameters
###############################################################################
#Graph Explorer
https://aka.ms/ge

#Simple Query
https://graph.microsoft.com/v1.0/me
https://graph.microsoft.com/v1.0/users
https://graph.microsoft.com/v1.0/users/m.muster@icewolf.ch

#Select
https://graph.microsoft.com/v1.0/me?$Select=givenName,surname

#Filter
https://graph.microsoft.com/v1.0/users?$filter=startswith(surname,'Boh')
https://graph.microsoft.com/v1.0/users?$filter=givenName eq 'Andres'&$count=true
https://graph.microsoft.com/v1.0/users?$filter=accountEnabled eq true
#Header: ConsistencyLevel: eventual


#Filter and Select
https://graph.microsoft.com/v1.0/users?$filter=startswith(surname,'Boh')&$Select=givenName,surname,DisplayName


###############################################################################
# Get-MgUser
# https://docs.microsoft.com/en-us/powershell/module/microsoft.graph.users/get-mguser?view=graph-powershell-1.0
###############################################################################
Get-MgUser -UserId "m.muster@icewolf.ch"
Get-MgUser -ConsistencyLevel eventual -Count userCount -Search '"DisplayName:Muster"'
Get-MgUser -Search '"UserPrincipalName:Muster"' -ConsistencyLevel "eventual"

###############################################################################
# Get-MgGroup
# https://docs.microsoft.com/en-us/powershell/module/microsoft.graph.groups/get-mggroup?view=graph-powershell-1.0
###############################################################################
Get-MgGroup
Get-MgGroup |  Format-List Id, DisplayName, Description, GroupTypes
Get-MgGroup -Filter "DisplayName eq 'AAD-IcewolfUsers'" | Format-List Id, DisplayName, Description, GroupTypes
Get-MgGroup -Filter "displayName eq 'PostmasterGraphRestriction'"

###############################################################################
# Get-MgGroupMember
# https://docs.microsoft.com/en-us/powershell/module/microsoft.graph.groups/get-mggroupmember?view=graph-powershell-1.0
###############################################################################
$GroupObjectID = "d59c6475-95a4-48ec-bb0a-4e074e73d32e"
$Members = Get-MgGroupMember -GroupId $GroupObjectID -All
$Members
$Members[0]
$Members[0] | fl
$Members[0].AdditionalProperties
$Members.AdditionalProperties

#AzureAD 
Measure-Command -Expression {$Members = Get-AzureADGroupMember -ObjectId "6c10161b-f0f1-4615-afbd-6cd1b31679e3" -All:$true}

#MG PowerShell
Measure-Command -Expression {$Members = Get-MgGroupMember -GroupId "6c10161b-f0f1-4615-afbd-6cd1b31679e3" -All}

###############################################################################
# Add / Remove Direct Assigned Licenses
# https://blog.icewolf.ch/archive/2021/11/29/hinzufugen-und-entfernen-von-m365-lizenzen-mit-microsoft-graph-powershell.aspx 
###############################################################################

#Connect
Connect-MgGraph -Scopes User.ReadWrite.All, Directory.ReadWrite.All

#Lizenz vom Benutzer anzeigen
Get-MgUserLicenseDetail -UserId "m.muster@icewolf.ch"

#Lizenz entfernen
Set-MgUserLicense -UserId "m.muster@icewolf.ch" -AddLicenses @() -RemoveLicenses @('e43b5b99-8dfb-405f-9987-dc307f34bcbd') #PhoneSystem

#Lizenz hinzufügen
Set-MgUserLicense -UserId "m.muster@icewolf.ch" -AddLicenses @{SkuId = 'e43b5b99-8dfb-405f-9987-dc307f34bcbd'} -RemoveLicenses @() #PhoneSystem

#Reprocess User License
Import-Module Microsoft.Graph.Users.Actions
Invoke-MgLicenseUser -UserId "m.muster@icewolf.ch"

#Product names and service plan identifiers for licensing
#https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference

#List Licenses in Tenant
Get-MgSubscribedSku
(Get-MgSubscribedSku)[0] | Format-List
(Get-MgSubscribedSku)[0].PrepaidUnits

###############################################################################
# SKU's an License with MgGraph and PSCustomObject
###############################################################################
#Array with all needed Properties using PSCustomObject
$ArraySKUS = @()
$SKUS = Get-MgSubscribedSku
Foreach ($SKU in $SKUS)
{
    #$ArraySKU = @()
    $AppliesTo = $SKU.AppliesTo
    $CapabilityStatus = $SKU.CapabilityStatus
    $SkuId = $SKU.SkuId
    $SkuPartNumber = $SKU.SkuPartNumber
    $ConsumedUnits = $SKU.ConsumedUnits
    $Enabled = $SKU.PrepaidUnits.Enabled
    $Suspended = $SKU.PrepaidUnits.Suspended
    $Warning = $SKU.PrepaidUnits.Warning
    $SKUObject = [PSCustomObject]@{
        AppliesTo             = $AppliesTo
        CapabilityStatus     = $CapabilityStatus
        SkuId                = $SkuId
        SkuPartNumber        = $SkuPartNumber
        ConsumedUnits        = $ConsumedUnits
        Enabled                = $Enabled
        Suspended            = $Suspended
        Warning                = $Warning
    }
    $ArraySKUS += $SKUObject
}
$ArraySKUS | Format-Table

###############################################################################
# Graph PowerShell Conversion Analyzer
# https://graphpowershell.merill.net/
###############################################################################