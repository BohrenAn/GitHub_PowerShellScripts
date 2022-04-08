###############################################################################
# Demo01-SQLDB-Biceps.ps1
# Create SQL Server / Firewall Rule / SQL Database with Biceps
# 08.04.2022 V0.1 - Initial Draft - Andres Bohren
###############################################################################

<#
Install Bicep tools
https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install

winget show microsoft.bicep
winget install -e --id Microsoft.Bicep

Export-AzResourceGroup -ResourceGroupName "your_resource_group_name" -Path ./main.json
bicep decompile main.json
bicep build main.json

#Bicep Playground
https://bicepdemo.z22.web.core.windows.net/

Connect-AzAccount
$TemplateFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-ResourceGroup-Template.json"
$ParameterFile = "https://raw.githubusercontent.com/BohrenAn/GitHub_PowerShellScripts/main/Azure/Demo03-ResourceGroup-Parameters.json"
#>

Connect-AzAccount
$TemplateFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo04-ResourceGroup-Template.bicep"
$ParameterFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo04-ResourceGroup-Parameters.json"
$Location = "westeurope"
New-AzDeployment -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -Location $Location


#$Location = "westeurope"
#New-AzSubscriptionDeployment -Location $Location -TemplateFile <path-to-bicep>


###############################################################################
# New-AzResourceGroupDeployment (Create SQL Server / Database / Firewall Rules)
# https://docs.microsoft.com/en-us/powershell/module/az.resources/new-azresourcegroupdeployment?view=azps-7.4.0
###############################################################################

$Securestring = ConvertTo-SecureString "SloppyJoe!" -AsPlainText -Force
$TemplateFile = "https://github.com/BohrenAn/GitHub_PowerShellScripts/blob/main/Azure/Demo03-SQLDB-Template.json"
$ParameterFile = "https://github.com/BohrenAn/GitHub_PowerShellScripts/blob/main/Azure/Demo03-SQLDB-Parameters.json"

$Securestring = ConvertTo-SecureString "SloppyJoe!" -AsPlainText -Force
$TemplateFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo04-SQLDB-Template.bicep"
$ParameterFile = "C:\GIT_WorkingDir\GitHub_PowerShellScripts\Azure\Demo04-SQLDB-Parameters.json"
$ResourceGroup = "RG_Demo04"
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -administratorLoginPassword $Securestring


#$ResourceGroup = "RG_Demo04"
#New-AzManagementGroupDeployment -ResourceGroupName $ResourceGroup -TemplateFile <path-to-bicep>
#-Location <location>