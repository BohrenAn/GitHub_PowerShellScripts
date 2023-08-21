###############################################################################
# Using Managed Identity with Microsoft Teams on Azure Automation
# 19.08.2023 - Initial Version - Andres Bohren @andresbohren
###############################################################################



###############################################################################
#Connect to Azure
###############################################################################
Connect-AzAccount -Tenant icewolfch.onmicrosoft.com

###############################################################################
#Get Automation Account
###############################################################################
Get-AzAutomationAccount

###############################################################################
#Check AzAutomation Module
###############################################################################
$accountName = 'icewolfautomation'
$rgName = 'RG_DEV'
Get-AzAutomationModule -AutomationAccountName $accountName -ResourceGroupName $rgName | where {$_.Name -eq "MicrosoftTeams"}

###############################################################################
#Get Automation Account Managed Identity
###############################################################################
$accountName = 'icewolfautomation'
$rgName = 'RG_DEV'
$AA = Get-AzAutomationAccount -Name $accountName -ResourceGroupName $rgName
$AA.Identity


###############################################################################
# Connect to Microsoft Graph
###############################################################################
Connect-MgGraph -Scopes Application.ReadWrite.All

###############################################################################
# Get Service Principal using objectId
###############################################################################
$SP = Get-MgServicePrincipal -all | where {$_.DisplayName -eq "icewolfautomation"}
$SPID = $SP.Id

###############################################################################
# Get MS Graph App role assignments using objectId of the Service Principal
###############################################################################
$assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $SPID -All 
$assignments | fl


###############################################################################
# Permission needed for Teams Application Authentication 
###############################################################################
#Application-based authentication in Teams PowerShell Module
#https://learn.microsoft.com/en-us/MicrosoftTeams/teams-powershell-application-authentication?WT.mc_id=M365-MVP-5004983#setup-application-based-authentication
#-Organization.Read.All
#-User.Read.All
#-Group.ReadWrite.All
#-AppCatalog.ReadWrite.All
#-TeamSettings.ReadWrite.All
#-Channel.Delete.All
#-ChannelSettings.ReadWrite.All,
#-ChannelMember.ReadWrite.All


###############################################################################
# Graph ResourceId
###############################################################################
$GraphResource = Get-MgServicePrincipal -all | where {$_.DisplayName -eq "Microsoft Graph"}
$GraphResource | fl
$GraphResourceID = $GraphResource.Id
$GraphResourceID

###############################################################################
# Microsoft Graph permissions reference
###############################################################################
#Microsoft Graph permissions reference
#https://learn.microsoft.com/en-us/graph/permissions-reference
#-Organization.Read.All	Application	498476ce-e0fe-48b0-b801-37ba7e2685c6
#-User.Read.All	Application	df021288-bdef-4463-88db-98f22de89214
#-Group.ReadWrite.All	Application	62a82d76-70ea-41e2-9197-370581804d09
#-AppCatalog.ReadWrite.All	Application	dc149144-f292-421e-b185-5953f2e98d7f
#-TeamSettings.ReadWrite.All	Application	bdd80a03-d9bc-451d-b7c4-ce7c63fe3c8f
#-Channel.Delete.All	Application	6a118a39-1227-45d4-af0c-ea7b40d210bc
#-ChannelSettings.ReadWrite.All	Application	243cded2-bd16-4fd6-a953-ff8177894c3d
#-ChannelMember.ReadWrite.All	Application	35930dcf-aceb-4bd1-b99a-8ffed403c974

###############################################################################
#Add AppRole to Service Principal
###############################################################################
$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "498476ce-e0fe-48b0-b801-37ba7e2685c6" # Organization.Read.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "62a82d76-70ea-41e2-9197-370581804d09" # Group.ReadWrite.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "dc149144-f292-421e-b185-5953f2e98d7f" # AppCatalog.ReadWrite.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "bdd80a03-d9bc-451d-b7c4-ce7c63fe3c8f" # TeamSettings.ReadWrite.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "6a118a39-1227-45d4-af0c-ea7b40d210bc" # Channel.Delete.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "6a118a39-1227-45d4-af0c-ea7b40d210bc" # Channel.Delete.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "243cded2-bd16-4fd6-a953-ff8177894c3d" # ChannelSettings.ReadWrite.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

$params = @{
    ServicePrincipalId = $SPID  # managed identity object id
    PrincipalId = $SPID  # managed identity object id
    ResourceId = $GraphResourceID # Microsoft.Graph
    AppRoleId = "35930dcf-aceb-4bd1-b99a-8ffed403c974" # ChannelMember.ReadWrite.All
}
New-MgServicePrincipalAppRoleAssignedTo @params

###############################################################################
#Add Service Principal to Teams Administrator
###############################################################################
$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Teams Administrator'").id
New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $SPID -RoleDefinitionId $roleId -DirectoryScopeId "/"


###############################################################################
# Demo Teams Runbook
###############################################################################
Connect-MicrosoftTeams -Identity
$Teams = Get-Team
Write-Output "Found $($teams.Count) teams"
Disconnect-MicrosoftTeams

## Get-CS / Set-CS Commands do not work ##
###############################################################################
#Add Service Principal to Teams Administrator
###############################################################################
$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Skype for Business Administrator'").id
New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $SPID -RoleDefinitionId $roleId -DirectoryScopeId "/"

###############################################################################
# Demo Teams Runbook
###############################################################################
Connect-MicrosoftTeams -Identity
$Teams = Get-Team
Write-Output "Found $($teams.Count) teams"
Get-CsOnlineUser -Identity a.bohren@icewolf.ch | fl *Ent*,*host*,*voice*, *line*
Disconnect-MicrosoftTeams
