###############################################################################
# CheckPSModules from PSGallery
# Checks the Array against CSV from Azure Storage
# Send a Mail about new Modules / Current Modules
# 14.03.2022 V0.1 - Initial Draft - Andres Bohren
###############################################################################
#Needed Modules
# -MSAL.PS
###############################################################################
#Needed Variables
# -AutomationVariable "StorageAccountName"
# -AutomationVariable "StorageAccountKey
# -AutomationVariable "DelegatedMailAppID"
# -AutomationVariable "TenantId"
# -AutomationCertificate "O365Powershell2"
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



###############################################################################
# Main Script
###############################################################################

#Get Automation Variables
Write-Output "Getting Automation Variables"
$StorageAccountName = Get-AutomationVariable -Name "StorageAccountName"
Write-Output "StorageAccountName --> $StorageAccountName"

$StorageAccountKey = Get-AutomationVariable -Name "StorageAccountKey"
#Write-Output "StorageAccounKey --> $StorageAccountKey"

$AppID = Get-AutomationVariable -Name "DelegatedMailAppID"
Write-Output "AppID --> $AppID"

$TenantID = Get-AutomationVariable -Name "TenantId"
Write-Output "TenantId --> $StorageAccountName"

#Get Certificate
Write-Output "Getting Automation Certificate"
$Certificate = Get-AutomationCertificate -name "O365Powershell2"
$CertificateThumbprint = $Certificate.ThumbPrint
Write-Output "CertificateThumbprint --> $CertificateThumbprint"

#Define the path, where the file gets saved. It just takes the location of the script.
#$path = Split-Path -parent $PSCommandPath
$path = $env:temp 

#Check Public IP
$PublicIP = (Invoke-WebRequest -uri "http://ifconfig.me/ip" -UseBasicParsing).Content
Write-Output "Public IP: $PublicIP"

###############################################################################
# Get AccessToken with MSAL
###############################################################################
#Authenticate with Certificate

Import-Module MSAL.PS
$TenantId = $TenantID
$AppID = $AppID #DelegatedMail
$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
$Scope = "https://graph.microsoft.com/.default" 

$CertificateThumbprint = $CertificateThumbprint #O365Powershell2.cer
$Token = Get-MsalToken -ClientId $AppID -ClientCertificate $Certificate -TenantId $TenantID -Scope $Scope -RedirectUri $RedirectUri
$AccessToken = $Token.AccessToken
#Write-Output "AccessToken: $AccessToken"


###############################################################################
# Check PSGallery Modules
###############################################################################
#Create Empty Array
$MyArray = @()

$Modules = @("AZ","MSOnline", "AzureADPreview", "ExchangeOnlineManagement", "Icewolf.EXO.SpamAnalyze", "MicrosoftTeams", "Microsoft.Online.SharePoint.PowerShell","PnP.PowerShell" , "ORCA", "O365CentralizedAddInDeployment", "MSCommerce", "WhiteboardAdmin", "Microsoft.Graph", "MSAL.PS", "MSIdentityTools" )
foreach ($Module in $Modules)
{
	#Check GA Version
	$Result = Find-Module -Name $Module
	$Version = $Result.Version
	Write-Output "GA: $Module $Version"

	#Create Custom Object to Store Information
	$myObject = [PSCustomObject]@{
		Release     = 'GA'
		Module = $Module
		Version    = $Version
	}
	#Add to Array
	$MyArray += $myObject

	#Check PreRelease Version
	$Result = Find-Module -Name $Module -AllowPrerelease
	$Version = $Result.Version
	Write-Output "PreRelease: $Module $Version"

	#Create Custom Object to Store Information
	$myObject = [PSCustomObject]@{
		Release     = 'PreRelease'
		Module = $Module
		Version    = $Version
	}
	#Add to Array
	$MyArray += $myObject

}

#Write-Output "Array"
#$MyArray


#Download CSV from Azure Storage
Write-Output "Download PSModules.csv from AzureStorage"
$DestinationFile = $path + "\PSModules.csv"
Write-Output "DEBUG: DestinationFile: $DestinationFile"
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
Get-AzStorageFileContent -ShareName "csv" -Path "/PSModules.csv" -Context $StorageContext -Destination $DestinationFile -Erroraction SilentlyContinue
$CSV = Import-CSV -Path $DestinationFile

$Compare = Compare-Object -ReferenceObject $MyArray -DifferenceObject $CSV -Property Release,Module,Version
#$Compare

#Export CSV
Write-Output "Export CSV"
$MyArray | Export-CSV -Path $DestinationFile -encoding UTF8 -NoTypeInformation

#Upload Logfile
Write-Output "Upload PSModules.csv to AzureStorage"
Set-AzStorageFileContent -ShareName "csv" -Source $DestinationFile -Path "PSModules.csv" -Context $StorageContext -Force #-Erroraction Stop

###############################################################################
# Sends the Admin Mail
###############################################################################
Write-Output "Send Admin Mail"
$table = [PSCustomobject]$MyArray | ConvertTo-Html -Fragment -As Table

#Check if Compare has found a diffrence
If ($Compare -eq $null)
{ 
	$table2 = "No diffrence detected"
} else {
	$Compare2 = $Compare | where {$_.SideIndicator -eq "<="}
	$table2 = [PSCustomobject]$Compare2 | ConvertTo-Html -Fragment -As Table
}

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
	<p>New Modules:</p>
	<p>$table2</p>
	<p>Daily PS Module Check</p>
	<p>$table</p>
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
        "subject": "PS Modules Check",
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
$result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType

Write-Output "Script finished"

