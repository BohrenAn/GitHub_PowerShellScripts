###############################################################################
# Azure Runbook to update the Microsoft.Graph Modules for PowerShell 5 / 7
# Requires Modules:
# - PackageManagement
# - PowerShellGet
# 2023.03.30 - Updated Version - Andres Bohren
# 2024.03.03 - Updated PowerShell 5/7.2
###############################################################################
# Requirements
# Az.Accounts 2.15.1
# Az.Automation 1.10.0
# PowerShellGet 2.2.5
# PackageManagement 1.4.8.1

###############################################################################
#Get Modules
###############################################################################
$accountName = 'icewolfautomation'
$rgName = 'RG_DEV'
$Modules = @()
$Modules += "Microsoft.Graph.Authentication"
$Modules += "Microsoft.Graph.Users"
$Modules += "Microsoft.Graph.Users.Actions"
$Modules += "Microsoft.Graph.Groups"
$Modules += "Microsoft.Graph.Identity.DirectoryManagement"
$Modules += "Microsoft.Graph.Mail"
$Modules += "Microsoft.Graph.Beta.Security"

###############################################################################
#ModuleVersionToInstall
###############################################################################
Write-Output "Import-Module PowerShellGet"
Import-Module PowerShellGet
Write-Output "Import-Module PackageManagement"
Import-Module PackageManagement
$GraphModule = Find-Module Microsoft.Graph
$moduleVersion = $GraphModule.Version
Write-Output "Graph Module: $moduleVersion"


###############################################################################
#Connect to Azure
###############################################################################
Write-Output "Connect-AzAccount"
Connect-AzAccount -Identity


###############################################################################
#Add Module
###############################################################################
#For Microsoft.Graph it is important that Microsoft.Graph.Authentication is installed first due to dependencys
Write-Output "Add PowerShell 5.1 Modules"
$RuntimeVersion = "5.1" #5.1, 7.2
$ModuleName = "Microsoft.Graph.Authentication"

Write-Output "Install ModuleName: $ModuleName Version: $moduleVersion RuntimeVersion: $RuntimeVersion"
$Result = New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion" -RuntimeVersion $RuntimeVersion

#Wait until Module is installed
Do {
    $Module = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | Where-Object {$_.Name -match "$ModuleName"}   
    Write-Output "State: $($Module.ProvisioningState) > Check again in 15 Seconds"
    Start-Sleep -Seconds 15
} until ($Module.ProvisioningState -eq "Succeeded")

#Install the Rest of the Modules
Foreach ($ModuleName in $Modules)
{
    Write-Output "Install ModuleName: $ModuleName Version: $moduleVersion RuntimeVersion: $RuntimeVersion"
    $Result = New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion" -RuntimeVersion $RuntimeVersion
}


###############################################################################
# Add Graph Modules PS7
###############################################################################
Write-Output "Add PowerShell 7.2 Modules"
$RuntimeVersion = "7.2" #5.1, 7.2
$ModuleName = "Microsoft.Graph.Authentication"
Write-Output "Install ModuleName: $ModuleName Version: $moduleVersion RuntimeVersion: $RuntimeVersion"
$Result = New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion" -RuntimeVersion $RuntimeVersion

#Wait until Module is installed
Do {
    $Module = Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name "$ModuleName" -RuntimeVersion $RuntimeVersion 
    Write-Output "State: $($Module.ProvisioningState) > Check again in 15 Seconds"
    Start-Sleep -Seconds 15
} until ($Module.ProvisioningState -eq "Succeeded")

#Install the Rest of the Modules
Foreach ($ModuleName in $Modules)
{
    Write-Output "Install ModuleName: $ModuleName Version: $moduleVersion RuntimeVersion: $RuntimeVersion"
    $Result = New-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion" -RuntimeVersion $RuntimeVersion
}

###############################################################################
#Disconnect from Azure
###############################################################################
Write-Output "Disconnect-AzAccount"
Disconnect-AzAccount
