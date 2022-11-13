###############################################################################
# Exchange Online with Azure Automation Account and Managed Identity
# 12.11.2022 - V1.0 - Initial Version - Andres Bohren
###############################################################################
#Some commands have been copied from here
#https://onprem.wtf/post/how-to-connect-exchange-online-managed-identity/

#Connect to Azure
Connect-AzAccount

#Get Automation Account
Get-AzAutomationAccount

#Get Specific Automation Account
$accountName = 'icewolfautomation'
$rgName = 'RG_DEV'
$AA = Get-AzAutomationAccount -Name $accountName -ResourceGroupName $rgName
$AA.Identity

#Get Service Principal
$ServicePrincipal = Get-AzADServicePrincipal -DisplayName $accountName
$SPID = $ServicePrincipal.ID

#Check AzAutomation Module
Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | where {$_.Name -eq "ExchangeOnlineManagement"}

#Add ManageAsApp to Service Principal
Connect-MgGraph
$params = @{
	ServicePrincipalId = $SPID  # managed identity object id
	PrincipalId = $SPID  # managed identity object id
	ResourceId = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").id # Exchange online
	AppRoleId = "dc50a0fb-09a3-484d-be87-e023b12c6440" # Exchange.ManageAsApp
}
New-MgServicePrincipalAppRoleAssignedTo @params

#Add Service Principal to Exchange Administrator
$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").id
New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $SPID -RoleDefinitionId $roleId -DirectoryScopeId "/"

###############################################################################
# Code for Azure Automation Runbook
###############################################################################
#Connect to Exchange with Managed Identity
$tenant = "icewolfch.onmicrosoft.com"
Connect-ExchangeOnline -ManagedIdentity -Organization $tenant

#Get Accepted Domain
Get-AcceptedDomain | Format-Table DomainName, DomainType

#Disconnect Exchange Online
Disconnect-ExchangeOnline -Confirm:$False