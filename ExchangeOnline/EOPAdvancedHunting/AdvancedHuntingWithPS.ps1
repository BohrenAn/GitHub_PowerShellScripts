###############################################################################
# Defender for Office 365 - AdvancedHunting with PowerShell
# 2023.04.21 - Initial Version - Andres Bohren
###############################################################################
# Requires an Azure AD App with the following Permission
# APIs my Organization uses > Microsoft Threat Protection
# -Delegated: AdvancedHunting.Read
# -Application: AdvancedHunting.Read.All
# Powershell Modules
# - Install-Module MSAL.PS
# - Install-Module JWTDetails

#Application Authentication
$AppId = "23299ad3-9e6f-4390-a121-1e5a394a6914" #PSSecurity
$TenantId = "icewolfch.onmicrosoft.com"
$ThumbPrint = "07EFF3918F47995EB53B91848F69B5C0E78622FD"
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