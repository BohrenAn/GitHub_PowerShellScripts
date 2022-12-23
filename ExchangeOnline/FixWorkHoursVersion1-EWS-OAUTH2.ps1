###############################################################################
# FixWorkHoursVersion1 = Null Error
# Connect to Exchange Online with EWS (OAUTH2)
# V1.0 - April 2022 - Andres Bohren - Initial Version
# V1.1 - August 2022 - Andres Bohren - Changed from Basich Auth to OAUTH
# V1.2 - Dezember 2022 - Andres Bohren - Changed EWS Path to NUGET
###############################################################################
<#
Install-Module MSAL.PS
Install-Package Microsoft.Exchange.WebServices
No ApplicationAccessPolicy = Impersonation to All Mailboxes!

Permission: full_access_as_app
Manifest:
"requiredResourceAccess": [
 {
 "resourceAppId": "00000002-0000-0ff1-ce00-000000000000",
 "resourceAccess": [
  {
   "id": "dc890d15-9560-4a4c-9b7f-a736ec74ec40",
   "type": "Role"
  }
  ]
 }
],
#>


Param (
	[Parameter(Mandatory=$true)][string]$TargetMailbox
)

#Enable TLS 1.2 for PowerShell Session
Write-Host "Set TLS 1.2 for PowerShell Session" 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Variables
Write-Host "Getting Access Token"
Import-Module MSAL.PS
$TenantId = "icewolfch.onmicrosoft.com"
$AppID = "9c954d5f-1fc7-485c-958c-23f436ea06ab"
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$Scope = "https://outlook.office365.com/.default"
[string]$EWSURL = "https://outlook.office365.com/EWS/Exchange.asmx"

#Authenticate with Certificate
Clear-MsalTokenCache
$CertificateThumbprint = "07EFF3918F47995EB53B91848F69B5C0E78622FD"
$Certificate = Get-ChildItem -Path cert:\CurrentUser\my\$CertificateThumbprint
$Token = Get-MsalToken -ClientId $AppID -ClientCertificate $Certificate -TenantId $TenantID -Scope $Scope -RedirectUri $RedirectUri
$AccessToken = $Token.AccessToken
#$AccessToken

###############################################################################
# Load EWS Managed API DLL  and Connect to Exchange
###############################################################################
Write-Host "Connect to EWS"
#[string]$EwsApiDll = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
[string]$EwsApiDll = "C:\Program Files\PackageManagement\NuGet\Packages\Microsoft.Exchange.WebServices.2.2.0\lib\40\Microsoft.Exchange.WebServices.dll"
Import-Module -Name $EwsApiDll

#Connect to Exchange
#Create EWS Object and connect with OAuth
$EWService = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1)
$EWService.Url = $EWSURL
$OAuthCredentials = New-Object Microsoft.Exchange.WebServices.Data.OAuthCredentials($AccessToken)
$EWService.Credentials = $OAuthCredentials

	
#Connect to another Mailbox
$EWService.ImpersonatedUserId = new-object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $TargetMailbox) 

<#
###############################################################################
# List Folders
###############################################################################
$FolderView = New-Object Microsoft.Exchange.WebServices.Data.FolderView(300)
$FolderView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Deep
$Folders = $EWService.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$FolderView)
$Folders | Format-List DisplayName, id
#>

###############################################################################
#Associated Items
###############################################################################
Write-Host "Getting Accociated Items"
$ItemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView(1000)
$ItemView.Traversal = [Microsoft.Exchange.WebServices.Data.ItemTraversal]::Associated
$AssociatedItems = $EWService.FindItems([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Calendar,$ItemView)

foreach ($Item in $AssociatedItems)
{
	Write-Host ("Associated Item: " + $item.Subject + " ItemClass: " + $item.ItemClass)

	#Subject:IPM.Configuration.WorkHours
	If ($Item.ItemClass -eq "IPM.Configuration.WorkHours")
	{
		Write-Host ("Delete Item: " + $item.Subject + " ItemClass: " + $item.ItemClass) -ForegroundColor Red
		$Item.Delete([Microsoft.Exchange.WebServices.Data.DeleteMode]::HardDelete) 
	}
}

<#
C:\GIT_WorkingDir\GitHub_PowerShellScripts\ExchangeOnline\FixWorkHoursVersion1-EWS-OAUTH2.ps1 -TargetMailbox m.muster@icewolf.ch
$UPN = "h.muster@icewolf.ch"
$UPN = "demo02@icewolf.ch"
Set-MailboxRegionalConfiguration -Identity $UPN  -TimeZone "W. Europe Standard Time" -DateFormat "dd.MM.yyyy" -TimeFormat "HH:mm" -Language "de-CH" -ErrorAction Stop
Set-MailboxCalendarConfiguration -Identity $UPN -WeekStartDay Monday -WorkDays Weekdays -WorkingHoursStartTime 08:00:00 -WorkingHoursEndTime 17:00:00 -WorkingHoursTimeZone "W. Europe Standard Time" -ShowWeekNumbers $True -ErrorAction Stop

$Mailboxes = Get-Mailbox
Foreach ($MBX in $Mailboxes)
{
	$UPN = $MBX.UserPrincipalName
	Write-Host "Working on: $UPN"
	Set-MailboxRegionalConfiguration -Identity $UPN  -TimeZone "W. Europe Standard Time" -DateFormat "dd.MM.yyyy" -TimeFormat "HH:mm" -Language "de-CH" -ErrorAction Stop
	Set-MailboxCalendarConfiguration -Identity $UPN -WeekStartDay Monday -WorkDays Weekdays -WorkingHoursStartTime 08:00:00 -WorkingHoursEndTime 17:00:00 -WorkingHoursTimeZone "W. Europe Standard Time" -ShowWeekNumbers $True -ErrorAction Stop
}
#>

