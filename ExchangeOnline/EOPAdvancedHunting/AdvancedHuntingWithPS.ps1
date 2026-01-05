###############################################################################
# Defender for Office 365 - AdvancedHunting with PowerShell
# 2023-04-21 - Initial Version - Andres Bohren
# 2026-01-05 - Updated for PSMSALNet and PowerShell 7.x - Andres Bohren
###############################################################################
# Requires an Azure AD App with the following Permission
# APIs my Organization uses > Microsoft Threat Protection
# -Delegated: AdvancedHunting.Read
# -Application: AdvancedHunting.Read.All
# Powershell Modules
# - Install-Module MSAL.PS > PowerShell 5.1
# - Install-Module PSMSALNet > PowerShell 7.x
# - Install-Module JWTDetails

###############################################################################
# Powershell 5.1
###############################################################################
#Application Authentication
$AppId = "23299ad3-9e6f-4390-a121-1e5a394a6914" #PSSecurity
$TenantId = "icewolfch.onmicrosoft.com"
$ThumbPrint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4
$Certificate = Get-ChildItem Cert:\CurrentUser\My\ | Where-Object {$_.Thumbprint -eq $ThumbPrint}
Import-Module MSAL.PS
Clear-MsalTokenCache
$Scopes = "https://api.security.microsoft.com/.default"
$Token = Get-MsalToken -ClientId $AppId -ClientCertificate $Certificate  -TenantId $TenantId -Scopes $Scopes
$AccessToken = $Token.AccessToken
Get-JWTDetails -token $AccessToken

#Delegated Authentication
$AppId = "23299ad3-9e6f-4390-a121-1e5a394a6914" #PSSecurity
$TenantId = "icewolfch.onmicrosoft.com"
Import-Module MSAL.PS
Clear-MsalTokenCache
$Scopes = "https://api.security.microsoft.com/.default"
$Token = Get-MsalToken -ClientId $AppId -TenantId $TenantId -Scopes $Scopes
$AccessToken = $Token.AccessToken
Get-JWTDetails -token $AccessToken


###############################################################################
# Powershell 7.x
###############################################################################
Import-Module PSMSALNet
$TenantId = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
$AppId = "23299ad3-9e6f-4390-a121-1e5a394a6914" #PSSecurity

# Authenticate with Certificate
$ThumbPrint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4
$Certificate = Get-ChildItem -Path cert:\CurrentUser\my\$Thumbprint
$CustomResource =  "https://api.security.microsoft.com/"

$HashArguments = @{
  ClientId = $AppID
  ClientCertificate = $Certificate
  TenantId = $TenantId
  Resource = "Custom"
  CustomResource = $CustomResource
}
$Token = Get-EntraToken -ClientCredentialFlowWithCertificate @HashArguments
$AccessToken = $Token.AccessToken
#$AccessToken
Get-JWTDetails -token $AccessToken

###############################################################################
# Advanced Hunting Query
###############################################################################

#KQL Query Oneliner
$query = 'EmailAttachmentInfo | limit 10'

#KQL Query Multiline
$query = @'
//TOP 10 URL Domains
EmailUrlInfo
| summarize count() by UrlDomain
| top 10 by count_
'@

$uri = "https://api.security.microsoft.com/api/advancedhunting/run"
$Headers = @{
	"Content-Type" = "application/json"
	"Authorization" = "Bearer "+ $AccessToken
	}
$Body = ConvertTo-Json -InputObject @{ 'Query' = $query }
$Response = Invoke-RestMethod -Method Post -Uri $uri -Headers $Headers -Body $Body
If ($Null -ne $Response)
{
	$Response.Results
}