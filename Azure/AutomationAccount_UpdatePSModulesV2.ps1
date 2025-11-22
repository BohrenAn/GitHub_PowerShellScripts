###############################################################################
# Azure Runbook to update the PowerShell Modules for Runtime Environment
# Requires Modules:
# - Microsoft.PowerShell.PSResourceGet
# 2025.01.02 - Initial Version - Andres Bohren
# 2025.11.22 - Updated NuPacketURI - Andres Bohren
###############################################################################
# Requirements
# - Azure Automation Account has Managed Identity
# - Managed Identity has "Contributor" Permission on Automation Account

###############################################################################
# Variables
###############################################################################
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEV"
$AutomationAccountName = "icewolfautomation"
$RuntimeEnvironment = "PowerShell-7.4"

###############################################################################
# Array of Modules
###############################################################################
$Modules = @()
$Modules += "Microsoft.PowerShell.PSResourceGet"
$Modules += "Az.Accounts"
$Modules += "Az.Automation"
$Modules += "Az.Storage"
$Modules += "Microsoft.Graph.Authentication"
$Modules += "Microsoft.Graph.Beta.Security"
$Modules += "Microsoft.Graph.Groups"
$Modules += "Microsoft.Graph.Identity.DirectoryManagement"
$Modules += "Microsoft.Graph.Mail"
$Modules += "Microsoft.Graph.Users"
$Modules += "Microsoft.Graph.Users.Actions"
$Modules += "MicrosoftTeams"
$Modules += "ExchangeOnlineManagement"
$Modules += "MSIdentityTools"
$Modules += "Microsoft.Online.SharePoint.PowerShell"
$Modules += "PnP.PowerShell"
$Modules += "PSMSALNet"


###############################################################################
# Connect to Azure
###############################################################################
Write-Output "Connect-AzAccount"
Connect-AzAccount -Identity

###############################################################################
# Add Powershell Package
###############################################################################
Foreach ($Module in $Modules)
{
    Write-Output "Module: $Module"
    $PSGallery = Find-PSResource -Name $Module
    $Version = $PSGallery.Version.ToString()
    #$NupkgURI = ("https://psg-prod-eastus.azureedge.net/packages/$Module.$Version.nupkg").ToLower()
    $NupkgURI = "https://www.powershellgallery.com/api/v2/package/$Module/$Version"

#Create NuGetURL
$body = @"
{
"properties": {
    "contentLink": {
    "uri": "$NupkgURI"
    }
  }
}
"@

    #Invoke Package Installation
    Invoke-AzRestMethod -Method "PUT" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/packages/$Module/?api-version=2023-05-15-preview" -Payload $Body
}

###############################################################################
# Get PowerShell Packages
###############################################################################
Do {
Write-Host "Checking Packages..."
$Result = Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/packages/?api-version=2023-05-15-preview"

$Object = ($Result.Content | convertFrom-Json).Value
$Array = $Object | Select-Object name, @{Name="Version";Expression={$_.properties.version}},@{Name="provisioningState";Expression={$_.properties.provisioningState}}
$Packages = $Array | Where-Object {$_.provisioningState -ne "Succeeded" -and $_.provisioningState -ne "Failed"}
Start-Sleep -Seconds 15
}
While ($Null -ne $Packages)
Write-Output "No installation pending"

###############################################################################
# Disconnect from Azure
###############################################################################
Write-Output "Disconnect-AzAccount"
Disconnect-AzAccount