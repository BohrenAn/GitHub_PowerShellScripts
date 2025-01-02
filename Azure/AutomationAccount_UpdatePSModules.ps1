###############################################################################
# Update PS Modules on Azure Automation Account
# 13.11.2022 - V1.0 - Initial Version - Andres Bohren
###############################################################################

#Connect to Azure
Connect-AzAccount

#Get Automation Account
Get-AzAutomationAccount

###############################################################################
#PowerShell 5.1 Modules
###############################################################################
#Get Modules
$accountName = 'icewolfautomation'
$rgName = 'RG_DEV'
$ModuleName = "Microsoft.Graph"
$Modules = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | Where-Object {$_.Name -match "$ModuleName"}
$Modules

#Remove Module
#For Microsoft.Graph it is important that Microsoft.Graph.Authentication is uninstalled last due to dependencys
Foreach ($Module in $Modules)
{
	If ($Module.Name -ne "Microsoft.Graph.Authentication")
	{
	$ModuleName = $Module.Name
	Write-Host "Remove ModuleName: $ModuleName"
	Remove-AzAutomationModule -AutomationAccountName $accountName -Name $ModuleName -ResourceGroupName $rgName -Confirm:$False -Force
	}
}
$ModuleName = "Microsoft.Graph.Authentication"
Write-Host "Remove ModuleName: $ModuleName"
Remove-AzAutomationModule -AutomationAccountName $accountName -Name $ModuleName -ResourceGroupName $rgName -Confirm:$False -Force


#Add Module
#For Microsoft.Graph it is important that Microsoft.Graph.Authentication is installed first due to dependencys
$ModuleName = "Microsoft.Graph.Authentication"
$moduleVersion = "1.17.0"
New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"

#Wait until Module is installed
Do {
	$Module = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | Where-Object {$_.Name -match "$ModuleName"}	
	Write-Host "State: $($Module.ProvisioningState) > Check again in 15 Seconds"
	Start-Sleep -Seconds 15
} until ($Module.ProvisioningState -eq "Succeeded")

#Install the Rest of the Modules
$Modules = @()
$Modules += "Microsoft.Graph.Users"
$Modules += "Microsoft.Graph.Users.Actions"
$Modules += "Microsoft.Graph.Groups"
$moduleVersion = "1.17.0"
Foreach ($ModuleName in $Modules)
{
	Write-Host "ModuleName: $ModuleName"
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
$ModuleName = "Microsoft.Graph.Authentication"
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
$Modules = @()
$Modules += "Microsoft.Graph.Authentication"
$Modules += "Microsoft.Graph.Users"
$Modules += "Microsoft.Graph.Users.Actions"
$Modules += "Microsoft.Graph.Groups"

#For Microsoft.Graph it is important that Microsoft.Graph.Authentication is uninstalled last due to dependencys
Foreach ($ModuleName in $Modules)
{
	If ($ModuleName -ne "Microsoft.Graph.Authentication")
	{
	Write-Host "Remove ModuleName: $ModuleName"
	Invoke-AzRestMethod `
		-Method DELETE `
		-SubscriptionId $subscriptionId `
		-ResourceGroupName $rgName `
		-ResourceProviderName Microsoft.Automation `
		-ResourceType automationAccounts `
		-Name $accountName/powershell7Modules/$ModuleName `
		-ApiVersion 2019-06-01
	}
}
$ModuleName = "Microsoft.Graph.Authentication"
Write-Host "Remove ModuleName: $ModuleName"
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
$ModuleName = "Microsoft.Graph.Authentication"
$moduleVersion = "1.17.0"

#Install Microsoft.Graph.Authentication
$Payload = @"
	{"properties":
		{"contentLink":
			{"uri":"https://www.powershellgallery.com/api/v2/package/$ModuleName/$moduleVersion"}
		}
	}
"@

Write-Host "Install ModuleName: $ModuleName"

Invoke-AzRestMethod `
	-Method PUT `
	-SubscriptionId $subscriptionId `
	-ResourceGroupName $rgName `
	-ResourceProviderName Microsoft.Automation `
	-ResourceType automationAccounts `
	-Name $accountName/powershell7Modules/$ModuleName `
	-ApiVersion 2019-06-01 `
	-Payload $Payload

#Wait until Module is installed
Do {
	$Result = Invoke-AzRestMethod `
	-Method GET `
	-SubscriptionId $subscriptionId `
	-ResourceGroupName $rgName `
	-ResourceProviderName Microsoft.Automation `
	-ResourceType automationAccounts `
	-Name $accountName/powershell7Modules/$ModuleName `
	-ApiVersion 2019-06-01 

	$ProvisioningState = (($Result.Content | ConvertFrom-Json).Properties).provisioningState

	$Module = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | Where-Object {$_.Name -match "$ModuleName"}	
	Write-Host "State: $ProvisioningState > Check again in 15 Seconds"
	Start-Sleep -Seconds 15
} until ($ProvisioningState -eq "Succeeded")

#Now install the Rest of the Modules
$Modules = @()
$Modules += "Microsoft.Graph.Users"
$Modules += "Microsoft.Graph.Users.Actions"
$Modules += "Microsoft.Graph.Groups"
#$Modules += "Microsoft.Graph.Mail"
#$Modules += "Microsoft.Graph.Identity.Management"

Foreach ($ModuleName in $Modules)
{
$Payload = @"
	{"properties":
		{"contentLink":
			{"uri":"https://www.powershellgallery.com/api/v2/package/$ModuleName/$moduleVersion"}
		}
	}
"@

Write-Host "Install ModuleName: $ModuleName"

Invoke-AzRestMethod `
	-Method PUT `
	-SubscriptionId $subscriptionId `
	-ResourceGroupName $rgName `
	-ResourceProviderName Microsoft.Automation `
	-ResourceType automationAccounts `
	-Name $accountName/powershell7Modules/$ModuleName `
	-ApiVersion 2019-06-01 `
	-Payload $Payload
}