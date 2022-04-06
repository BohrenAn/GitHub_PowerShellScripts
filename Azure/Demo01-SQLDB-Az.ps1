###############################################################################
# Demo01-SQLDB-Az.ps1
# Create SQL Server / Firewall Rule / SQL Database with AZ.* Powershell Modules
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
$ResourceGroup = "RG_Demo01"
$Location = "westeurope"
New-AzResourceGroup -Name $ResourceGroup -Location $Location

###############################################################################
# Create SQL Server Object
# https://docs.microsoft.com/en-us/powershell/module/az.sql/new-azsqlserver?view=azps-7.3.2
###############################################################################
$Credential = Get-Credential
$SQLServerName = "icewolfsqldemo01"
$MinimalTLSVersion = "1.2"
New-AzSqlServer -ResourceGroupName $ResourceGroup -Location $Location -ServerName $SQLServerName -SqlAdministratorCredentials $Credential -MinimalTlsVersion $MinimalTLSVersion

#Get SQLServer
Get-AzSqlServer -ResourceGroupName $ResourceGroup | Format-List ResourceId, ServerName, FullyQualifiedDomainName, SqlAdministratorLogin, ResourceGroupName

###############################################################################
# Create SQL Server FirewallRule
# https://docs.microsoft.com/en-us/powershell/module/az.sql/new-azsqlserverfirewallrule?view=azps-7.3.2
###############################################################################
#Allow Azure
New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroup -ServerName $SQLServerName -AllowAllAzureIPs

#Add Corporate Public IP
$RuleName = "IcewolfPublicIP"
$StartIpAddress = "95.143.60.18" 
$EndIpAddress = "95.143.60.18"
New-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroup -ServerName $SQLServerName -FirewallRuleName $RuleName -StartIpAddress $StartIpAddress -EndIpAddress $EndIpAddress

#Get Firewall Rules
Get-AzSqlServerFirewallRule -ResourceGroupName $ResourceGroup -ServerName $SQLServerName

###############################################################################
# Create SQL Database
# https://docs.microsoft.com/en-us/powershell/module/az.sql/new-azsqldatabase?view=azps-7.3.2
###############################################################################
$DatabaseName = "db_demo01"
$Edition = "Basic"
New-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServerName -DatabaseName $DatabaseName -Edition $Edition
Get-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServerName 
Get-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $SQLServerName  | Format-List ResourceID, DatabaseName


###############################################################################
# Remove-AzResourceGroup
# https://docs.microsoft.com/en-us/powershell/module/az.resources/remove-azresourcegroup?view=azps-7.4.0
###############################################################################
$ResourceGroup = "RG_Demo01"
Remove-AzResourceGroup -Name $ResourceGroup -Force