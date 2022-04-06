###############################################################################
# Demo03-SQLDB-ARM.ps1 
# Create SQL Server / Firewall Rule / SQL Database with ARM Template (JSON)
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
$TemplateFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-ResourceGroup-Template.json"
$ParameterFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-ResourceGroup-Parameters.json"
New-AzDeployment -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -Location "westeurope"

###############################################################################
# New-AzResourceGroupDeployment (Create SQL Server / Database / Firewall Rules)
# https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-7.4.0
###############################################################################

$Securestring = ConvertTo-SecureString "SloppyJoe!" -AsPlainText -Force
$TemplateFile = "https://github.com/BohrenAn/GitHub_PowerShellScripts/blob/main/Azure/Demo03-SQLDB-Template.json"
$ParameterFile = "https://github.com/BohrenAn/GitHub_PowerShellScripts/blob/main/Azure/Demo03-SQLDB-Parameters.json"
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

$TemplateFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-ResourceGroup-Template.json"
$ParameterFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-ResourceGroup-Parameters.json"
az deployment sub create --template-uri $TemplateFile --parameters $ParameterFile --location "westeurope"


$Securestring = ConvertTo-SecureString "SloppyJoe!" -AsPlainText -Force
$TemplateFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-SQLDB-Template.json"
$ParameterFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-SQLDB-Parameters.json"
$ResourceGroup = "RG_Demo03"
az deployment group create --resource-group $ResourceGroup --template-uri $TemplateFile --parameters $ParameterFile administratorLoginPassword=$Securestring

###############################################################################
#Cleanup
###############################################################################
$ResourceGroup = "RG_Demo03"
az group delete --resource-group $ResourceGroup --yes