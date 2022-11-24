###############################################################################
# Create and Deploy Azure Automate Runbook with PowerShell 7
# 19.11.2022 - Initial Version - Andres Bohren
###############################################################################

#Connect to Azure
Connect-AzAccount

#Get Automation Account
Get-AzAutomationAccount

###############################################################################
# Create Runbook
###############################################################################
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


###############################################################################
# Publish Runbook
###############################################################################
Publish-AzAutomationRunbook -Name $RunbookName -AutomationAccountName $AccountName -ResourceGroupName $rgName

###############################################################################
# Get Schedule
###############################################################################
$accountName = "icewolfautomation"
$rgName = "RG_DEV"
Get-AzAutomationSchedule -AutomationAccountName $AccountName -ResourceGroupName $rgName
Get-AzAutomationSchedule -AutomationAccountName $AccountName -ResourceGroupName $rgName -Name "Weekly"

###############################################################################
# Link Schedule with Runbook
###############################################################################
$accountName = "icewolfautomation"
$rgName = "RG_DEV"
$scheduleName = "Weekly"
Register-AzAutomationScheduledRunbook -AutomationAccountName $accountName `
-Name $RunbookName -ScheduleName $scheduleName -ResourceGroupName $rgName 