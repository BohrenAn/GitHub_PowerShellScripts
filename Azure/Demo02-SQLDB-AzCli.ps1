###############################################################################
# Demo02-SQLDB-Az.ps1
# Create SQL Server / Firewall Rule / SQL Database with AZ CLI
# 05.04.2022 - Initial Version - Andres Bohren 
###############################################################################

###############################################################################
# Login with AzureCLI
###############################################################################
az login

###############################################################################
# Create Demo Resource Group
# https://docs.microsoft.com/en-us/cli/azure/group?view=azure-cli-latest#az-group-create
###############################################################################
$ResourceGroup = "RG_Demo02"
$Location = "westeurope"
az group create --location $Location --name $ResourceGroup

###############################################################################
# Create SQL Server Object
# https://docs.microsoft.com/en-us/cli/azure/sql/server?view=azure-cli-latest#az-sql-server-create
###############################################################################
$SQLServerName = "icewolfsqldemo02"
$AdminUser = "sqladmin"
$AdminPassword = "SloppyJoe!"
$MinimalTLSVersion = "1.2"
az sql server create --location $Location --resource-group $ResourceGroup --name $SQLServerName --admin-user $AdminUser --admin-password $AdminPassword --minimal-tls-version $MinimalTLSVersion
az sql server list --resource-group $ResourceGroup

###############################################################################
# Create SQL Server FirewallRule
# https://docs.microsoft.com/en-us/cli/azure/sql/server/firewall-rule?view=azure-cli-latest#az-sql-server-firewall-rule-create
###############################################################################
#Create SQL Server Firewall Rule for Azure
az sql server firewall-rule create -g $ResourceGroup -s $SQLServerName -n Azure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
#Create SQL Server Firewall Rule for Icewolf
$RuleName = "IcewolfPublicIP"
$StartIpAddress = "95.143.60.18" 
$EndIpAddress = "95.143.60.18"
az sql server firewall-rule create -g $ResourceGroup -s $SQLServerName -n $RuleName --start-ip-address $StartIpAddress --end-ip-address $EndIpAddress 

###############################################################################
# Create SQL Database in Azure
###############################################################################
$DatabaseName = "db_demo02"
$Edition = "Basic"
az sql db create --resource-group $ResourceGroup --server $SQLServerName --name $DatabaseName --zone-redundant $false --edition $Edition

###############################################################################
#Cleanup
###############################################################################
$ResourceGroup = "RG_Demo02"
az group delete --resource-group $ResourceGroup --yes