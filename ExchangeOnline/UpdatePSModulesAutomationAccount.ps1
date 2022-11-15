###############################################################################
# Update PS Modules on Azure Automation Account
# 13.11.2022 - V1.0 - Initial Version - Andres Bohren
###############################################################################

#Connect to Azure
Connect-AzAccount

#Get Automation Account
Get-AzAutomationAccount

#Get Modules
$accountName = 'icewolfautomation'
$rgName = 'RG_DEV'
$ModuleName = "ExchangeOnlineManagement"
$ModuleName = "Microsoft.Graph"
$Modules = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | Where-Object {$_.Name -match "$ModuleName"}
$Modules

#Remove Module
Foreach ($Module in $Modules)
{
	$ModuleName = $Module.Name
	Write-Host "Remove ModuleName: $ModuleName"
	Remove-AzAutomationModule -AutomationAccountName $accountName -Name $ModuleName -ResourceGroupName $rgName
}

#Add Module
Foreach ($Module in $Modules)
{
	$moduleVersion = "1.16.0"
	$ModuleName = $Module.Name
	Write-Host "ADD Module: $ModuleName"
	New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"
}

###############################################################################
#PowerShell 7 Modules
#https://github.com/Azure/azure-powershell/issues/16399
###############################################################################

###############################################################################
# GET PS7 Module
###############################################################################
$subscriptionId = "42ecead4-eae9-4456-997c-1580c58b54ba"
$accountName = "icewolfautomation"
$rgName = "RG_DEV"
#$ModuleName = "Microsoft.Graph.Mail"
#$ModuleName = "Microsoft.Graph.Users.Actions"
#$ModuleName = "Microsoft.Graph.Identity.DirectoryManagement"
#$ModuleName = "Microsoft.Graph.Authentication"
$ModuleName = "ExchangeOnlineManagement"
$Result = Invoke-AzRestMethod `
	-Method GET `
	-SubscriptionId $subscriptionId `
	-ResourceGroupName $rgName `
	-ResourceProviderName Microsoft.Automation `
	-ResourceType automationAccounts `
	-Name $accountName/powershell7Modules/$ModuleName `
	-ApiVersion 2019-06-01 

($Result.Content | ConvertFrom-Json).Properties

###############################################################################
#Delete PS7 Module
###############################################################################
$subscriptionId = "42ecead4-eae9-4456-997c-1580c58b54ba"
$accountName = "icewolfautomation"
$rgName = "RG_DEV"
#$ModuleName = "Microsoft.Graph.Mail"
#$ModuleName = "Microsoft.Graph.Users.Actions"
#$ModuleName = "Microsoft.Graph.Identity.DirectoryManagement"
$ModuleName = "Microsoft.Graph.Authentication"
Invoke-AzRestMethod `
	-Method DELETE `
	-SubscriptionId $subscriptionId `
	-ResourceGroupName $rgName `
	-ResourceProviderName Microsoft.Automation `
	-ResourceType automationAccounts `
	-Name $accountName/powershell7Modules/$ModuleName `
	-ApiVersion 2019-06-01
	
###############################################################################
#Add PS7 Module
###############################################################################
$subscriptionId = "42ecead4-eae9-4456-997c-1580c58b54ba"
$accountName = "icewolfautomation"
$rgName = "RG_DEV"
#$ModuleName = "Microsoft.Graph.Authentication"
#$ModuleName = "Microsoft.Graph.Mail"
#$ModuleName = "Microsoft.Graph.Users.Actions"
#$ModuleName = "Microsoft.Graph.Identity.DirectoryManagement"
#$moduleVersion = "1.16.0"
$ModuleName = "ExchangeOnlineManagement"
$moduleVersion = "3.0.0"
$Payload = @"
	{"properties":
		{"contentLink":
			{"uri":"https://www.powershellgallery.com/api/v2/package/$ModuleName/$moduleVersion"}
		}
	}
"@

Invoke-AzRestMethod `
	-Method PUT `
	-SubscriptionId $subscriptionId `
	-ResourceGroupName $rgName `
	-ResourceProviderName Microsoft.Automation `
	-ResourceType automationAccounts `
	-Name $accountName/powershell7Modules/$ModuleName `
	-ApiVersion 2019-06-01 `
	-Payload $Payload
	

###############################################################################
#Create Runbook with PowerShell 7
###############################################################################
$subscriptionId = "42ecead4-eae9-4456-997c-1580c58b54ba"
$accountName = "icewolfautomation"
$rgName = "RG_DEV"
$location = "West Europe"
$RunbookName = "DemoPS7"
$scriptContent = @'
	#Connect to Exchange with Managed Identity
	$tenant = "icewolfch.onmicrosoft.com"
	Connect-ExchangeOnline -ManagedIdentity -Organization $tenant

	#Get Accepted Domain
	Get-AcceptedDomain | Format-Table DomainName, DomainType

	#Disconnect Exchange Online
	Disconnect-ExchangeOnline -Confirm:$False
'@

Invoke-AzRestMethod -Method "PUT" -ResourceGroupName $rgName -ResourceProviderName "Microsoft.Automation" `
	-ResourceType "automationAccounts" -Name "${AccountName}/runbooks/${RunbookName}" -ApiVersion "2017-05-15-preview" `
	-Payload "{`"properties`":{`"runbookType`":`"PowerShell7`", `"logProgress`":false, `"logVerbose`":false, `"draft`":{}}, `"location`":`"${Location}`"}"

Invoke-AzRestMethod -Method "PUT" -ResourceGroupName $rgName -ResourceProviderName "Microsoft.Automation" `
	-ResourceType automationAccounts -Name "${AccountName}/runbooks/${RunbookName}/draft/content" -ApiVersion 2015-10-31 `
	-Payload "$scriptContent"

Publish-AzAutomationRunbook -Name $RunbookName -AutomationAccountName $AccountName -ResourceGroupName $rgName
	