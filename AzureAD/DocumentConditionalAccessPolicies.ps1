###############################################################################
# DocumentConditionalAccessPolicies.ps1
# An Approach to Document the PowerShell 
# 03.02.2022 - Initial Version - Andres Bohren
###############################################################################
<#
Export the JSON from Graph Explorer

MSGraph: List Conditional Access policies
https://learn.microsoft.com/en-us/graph/api/conditionalaccessroot-list-policies?view=graph-rest-1.0&tabs=http

So tried to use the Microsoft Graph Explorer https://aka.ms/ge
You need the Permission: Policy.Read.All

https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies
#>

#Get Conditional Access Policies
Import-Module Microsoft.Graph.Identity.SignIns
Connect-MgGraph -Scopes Policy.Read.All
$CAP = Get-MgIdentityConditionalAccessPolicy
$CAP

#Show Details of one Conditional Access Policy
$CAP[1] | Format-List
$CAP[1].Conditions | Format-List
$CAP[1].Conditions.Applications | Format-List
$CAP[1].GrantControls | Format-List
$CAP[1].SessionControls | Format-List

#List all Conditional Access Policies
#Layers of Objects are created with Labels and separated with "_"
$CAP | Select-Object Id, DisplayName, State, `
@{Label = "Conditions_Applications_ExcludeApplications"; Expression = { $_.Conditions.Applications.ExcludeApplications}}, `
@{Label = "Conditions_Applications_IncludeApplications"; Expression = { $_.Conditions.Applications.IncludeApplications}}, `
@{Label = "Conditions_Applications_IncludeAuthenticationContextClassReferences"; Expression = { $_.Conditions.Applications.IncludeAuthenticationContextClassReferences}}, `
@{Label = "Conditions_Applications_IncludeUserActions"; Expression = { $_.Conditions.Applications.IncludeUserActions}}, `
@{Label = "Conditions_Applications_AdditionalProperties"; Expression = { $_.Conditions.Applications.AdditionalProperties}}, `
@{Label = "Conditions_ClientAppTypes"; Expression = { $_.Conditions.ClientAppTypes}}, `
@{Label = "Conditions_ClientApplications_ExcludeServicePrincipals"; Expression = { $_.Conditions.ClientApplications.ExcludeServicePrincipals}}, `
@{Label = "Conditions_ClientApplications_IncludeServicePrincipals"; Expression = { $_.Conditions.ClientApplications.IncludeServicePrincipals}}, `
@{Label = "Conditions_Devices_DeviceFilter_Mode"; Expression = { $_.Conditions.Devices.DeviceFilter.Mode}}, `
@{Label = "Conditions_Devices_DeviceFilter_Rule"; Expression = { $_.Conditions.Devices.DeviceFilter.Rule}}, `
@{Label = "Conditions_Devices_DeviceFilter_AdditionalProperties"; Expression = { $_.Conditions.Devices.DeviceFilter.AdditionalProperties}}, `
@{Label = "Conditions_Locations_ExcludeLocations"; Expression = { $_.Conditions.Locations.ExcludeLocations}}, `
@{Label = "Conditions_Locations_IncludeLocations"; Expression = { $_.Conditions.Locations.IncludeLocations}}, `
@{Label = "Conditions_Platforms_ExcludePlatforms"; Expression = { $_.Conditions.Platforms.ExcludePlatforms}}, `
@{Label = "Conditions_Platforms_IncludePlatforms"; Expression = { $_.Conditions.Platforms.IncludePlatforms}}, `
@{Label = "Conditions_Platforms_AdditionalProperties"; Expression = { $_.Conditions.Platforms.AdditionalProperties}}, `
@{Label = "Conditions_ServicePrincipalRiskLevels"; Expression = { $_.Conditions.ServicePrincipalRiskLevels}}, `
@{Label = "Conditions_SignInRiskLevels"; Expression = { $_.Conditions.SignInRiskLevels}}, `
@{Label = "Conditions_UserRiskLevels"; Expression = { $_.Conditions.UserRiskLevels}}, `
@{Label = "Conditions_users_ExcludeGroups"; Expression = { $_.Conditions.Users.ExcludeGroups}}, `
@{Label = "Conditions_users_ExcludeRoles"; Expression = { $_.Conditions.Users.ExcludeRoles}}, `
@{Label = "Conditions_users_ExcludeUsers"; Expression = { $_.Conditions.Users.ExcludeUsers}}, `
@{Label = "Conditions_users_IncludeGroups"; Expression = { $_.Conditions.Users.IncludeGroups}}, `
@{Label = "Conditions_users_IncludeRoles"; Expression = { $_.Conditions.Users.IncludeRoles}}, `
@{Label = "Conditions_users_IncludeUsers"; Expression = { $_.Conditions.Users.IncludeUsers}}, `
@{Label = "Conditions_users_AdditionalProperties"; Expression = { $_.Conditions.Users.AdditionalProperties}}, `
@{Label = "Conditions_AdditionalProperties"; Expression = { $_.Conditions.AdditionalProperties}}, `
@{Label = "SessionControls_ApplicationEnforcedRestrictions_IsEnabled"; Expression = { $_.SessionControls.ApplicationEnforcedRestrictions.IsEnabled}}, `
@{Label = "SessionControls_ApplicationEnforcedRestrictions_AdditionalProperties"; Expression = { $_.SessionControls.ApplicationEnforcedRestrictions.AdditionalProperties}}, `
@{Label = "SessionControls_CloudAppSecurity_CloudAppSecurityType"; Expression = { $_.SessionControls.CloudAppSecurity.CloudAppSecurityType}}, `
@{Label = "SessionControls_CloudAppSecurity_IsEnabled"; Expression = { $_.SessionControls.CloudAppSecurity.IsEnabled}}, `
@{Label = "SessionControls_CloudAppSecurity_AdditionalProperties"; Expression = { $_.SessionControls.CloudAppSecurity.AdditionalProperties}}, `
@{Label = "SessionControls_DisableResilienceDefaults"; Expression = { $_.SessionControls.DisableResilienceDefaults}}, `
@{Label = "SessionControls_PersistentBrowser_IsEnabled"; Expression = { $_.SessionControls.PersistentBrowser.IsEnabled}}, `
@{Label = "SessionControls_PersistentBrowser_Mode"; Expression = { $_.SessionControls.PersistentBrowser.Mode}}, `
@{Label = "SessionControls_PersistentBrowser_AdditionalProperties"; Expression = { $_.SessionControls.PersistentBrowser.AdditionalProperties}}, `
@{Label = "SessionControls_SignInFrequency_AuthenticationType"; Expression = { $_.SessionControls.SignInFrequency.AuthenticationType}}, `
@{Label = "SessionControls_SignInFrequency_FrequencyInterval"; Expression = { $_.SessionControls.SignInFrequency.FrequencyInterval}}, `
@{Label = "SessionControls_SignInFrequency_IsEnabled"; Expression = { $_.SessionControls.SignInFrequency.IsEnabled}}, `
@{Label = "SessionControls_SignInFrequency_Type"; Expression = { $_.SessionControls.SignInFrequency.Type}}, `
@{Label = "SessionControls_SignInFrequency_Value"; Expression = { $_.SessionControls.SignInFrequency.Value}}, `
@{Label = "SessionControls_SignInFrequency_AdditionalProperties"; Expression = { $_.SessionControls.SignInFrequency.AdditionalProperties}}, `
@{Label = "SessionControls_AdditionalProperties"; Expression = { $_.SessionControls.AdditionalProperties}}, `
@{Label = "GrantControls_BuiltInControls"; Expression = { $_.GrantControls.BuiltInControls}}, `
@{Label = "GrantControls_Operator"; Expression = { $_.GrantControls.Operator}}, `
@{Label = "GrantControls_CustomAuthenticationFactors"; Expression = { $_.GrantControls.CustomAuthenticationFactors}}, `
@{Label = "GrantControls_TermsOfUse"; Expression = { $_.GrantControls.TermsOfUse}}