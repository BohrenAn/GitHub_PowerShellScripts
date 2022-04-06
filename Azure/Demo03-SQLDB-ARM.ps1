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
# New-AzDeployment (Create ResourceGroup)
# https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azdeployment?view=azps-7.4.0
###############################################################################
$TemplateFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-ResourceGroup-Template.json"
$ParameterFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-ResourceGroup-Parameters.json"
New-AzDeployment -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -Location "westeurope"

###############################################################################
# New-AzResourceGroupDeployment (Create SQL Server / Database / Firewall Rules)
# https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-7.4.0
###############################################################################

$Securestring = ConvertTo-SecureString "SloppyJoe!" -AsPlainText -Force
$TemplateFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-SQLDB-Template.json"
$ParameterFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-SQLDB-Parameters.json"
$ResourceGroup = "RG_Demo03"
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -administratorLoginPassword $Securestring

###############################################################################
# Remove-AzResourceGroup
# https://docs.microsoft.com/en-us/powershell/module/az.resources/remove-azresourcegroup?view=azps-7.4.0
###############################################################################
$ResourceGroup = "RG_Demo03"
Remove-AzResourceGroup -Name $ResourceGroup -Force


###############################################################################
# Deployment using Azure CLI
###############################################################################
az login

$TemplateFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-ResourceGroup-Template.json"
$ParameterFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-ResourceGroup-Parameters.json"
az deployment group create --template-uri $TemplateFile --parameters $ParameterFile --location "westeurope"


$Securestring = ConvertTo-SecureString "SloppyJoe!" -AsPlainText -Force
$TemplateFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-SQLDB-Template.json"
$ParameterFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo03-SQLDB-Parameters.json"
$ResourceGroup = "RG_Demo03"
az deployment group create --template-uri $TemplateFile --parameters $ParameterFile --location "westeurope"