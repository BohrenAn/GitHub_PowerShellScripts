###############################################################################
# Azure Runbook to update the Microsoft.Graph Modules for PowerShell 5 / 7
# - Uses Managed Identity 
# - Requires Contributor Permissions on Azure Automation you want to update
# Requires Modules:
# - PackageManagement
# - PowerShellGet
# 2023.03.30 - Updated Version - Andres Bohren
###############################################################################

#ModuleVersionToInstall
#$moduleVersion = "1.23.0"
$GraphModule = Find-Module Microsoft.Graph
$moduleVersion = $GraphModule.Version
Write-Output "Graph Module: $moduleVersion"

#Connect to Azure
Write-Output "Connect-AzAccount"
Connect-AzAccount -Identity

$Modules = @()
$Modules += "Microsoft.Graph.Authentication"
$Modules += "Microsoft.Graph.Users"
$Modules += "Microsoft.Graph.Users.Actions"
$Modules += "Microsoft.Graph.Groups"
$Modules += "Microsoft.Graph.Identity.DirectoryManagement"
$Modules += "Microsoft.Graph.Mail"

###############################################################################
#Get Modules
###############################################################################
$accountName = 'icewolfautomation'
$rgName = 'RG_DEV'
$ModuleName = "Microsoft.Graph"
$Modules = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | Where-Object {$_.Name -match "$ModuleName"}
$Modules

###############################################################################
#Remove Module
#For Microsoft.Graph it is important that Microsoft.Graph.Authentication is uninstalled last due to dependencys
###############################################################################
Foreach ($Module in $Modules)
{
    If ($Module.Name -ne "Microsoft.Graph.Authentication")
    {
    $ModuleName = $Module.Name
    Write-Output "Remove ModuleName: $ModuleName"
    Remove-AzAutomationModule -AutomationAccountName $accountName -Name $ModuleName -ResourceGroupName $rgName -Confirm:$False -Force
    }
}
$ModuleName = "Microsoft.Graph.Authentication"
Write-Output "Remove ModuleName: $ModuleName"
Remove-AzAutomationModule -AutomationAccountName $accountName -Name $ModuleName -ResourceGroupName $rgName -Confirm:$False -Force


Write-Output "Sleep for 30 Seconds"
Start-Sleep -Seconds 30

###############################################################################
#Add Module
###############################################################################
#For Microsoft.Graph it is important that Microsoft.Graph.Authentication is installed first due to dependencys
$ModuleName = "Microsoft.Graph.Authentication"

New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"

#Wait until Module is installed
Do {
    $Module = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | Where-Object {$_.Name -match "$ModuleName"}   
    Write-Output "State: $($Module.ProvisioningState) > Check again in 15 Seconds"
    Start-Sleep -Seconds 15
} until ($Module.ProvisioningState -eq "Succeeded")

#Install the Rest of the Modules
$Modules = @()
$Modules += "Microsoft.Graph.Users"
$Modules += "Microsoft.Graph.Users.Actions"
$Modules += "Microsoft.Graph.Groups"
$Modules += "Microsoft.Graph.Identity.DirectoryManagement"
$Modules += "Microsoft.Graph.Mail"
Foreach ($ModuleName in $Modules)
{
    Write-Output "ModuleName: $ModuleName"
    New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"
}

Write-Output "Done"



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
#For Microsoft.Graph it is important that Microsoft.Graph.Authentication is uninstalled last due to dependencys
Foreach ($ModuleName in $Modules)
{
    If ($ModuleName -ne "Microsoft.Graph.Authentication")
    {
    Write-Output "Remove ModuleName: $ModuleName"
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
Write-Output "Remove ModuleName: $ModuleName"
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

#Install Microsoft.Graph.Authentication
$Payload = @"
    {"properties":
        {"contentLink":
            {"uri":"https://www.powershellgallery.com/api/v2/package/$ModuleName/$moduleVersion"}
        }
    }
"@

Write-Output "Install ModuleName: $ModuleName"

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
    Write-Output "State: $ProvisioningState > Check again in 15 Seconds"
    Start-Sleep -Seconds 15
} until ($ProvisioningState -eq "Succeeded")


#Now install the Rest of the Modules
Foreach ($ModuleName in $Modules)
{
$Payload = @"
    {"properties":
        {"contentLink":
            {"uri":"https://www.powershellgallery.com/api/v2/package/$ModuleName/$moduleVersion"}
        }
    }
"@

Write-Output "Install ModuleName: $ModuleName"

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

Write-Output "Disconnect-AzAccount"
Disconnect-AzAccount
