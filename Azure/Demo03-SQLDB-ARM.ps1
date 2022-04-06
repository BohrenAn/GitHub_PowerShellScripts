###############################################################################
# SQLDB-Az.ps1 - Create SQL Server / Firewall Rule / SQL Database with AZ.* Powershell Modules
# 05.04.2022 - Initial Version - Andres Bohren 
###############################################################################

###############################################################################
# Connect AzAccount
###############################################################################
Connect-AzAccount

###############################################################################
# Set Subscription
###############################################################################
Set-AzContext [SubscriptionID/SubscriptionName]

###############################################################################
# Create Resource Group
# https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup?view=azps-7.4.0
###############################################################################
$ResourceGroup = "RG_Demo03"
$Location = "westeurope"
New-AzResourceGroup -Name $ResourceGroup -Location $Location

###############################################################################
# Create Resource Group
# https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroup?view=azps-7.4.0
###############################################################################
$projectName = Read-Host -Prompt "Enter the same project name"
$templateFile = Read-Host -Prompt "Enter the template file path and file name"
$resourceGroupName = "${projectName}rg"

New-AzResourceGroupDeployment `
  -Name DeployLocalTemplate `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $templateFile `
  -projectName $projectName `
  -verbose