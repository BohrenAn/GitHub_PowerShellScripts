###############################################################################
# TeamsAppAuthentication.ps1
# How to use Microsoft Teams with Azure AD Application Authentication 
# with Certificate or PFX File
# 03.02.2023 - Initial Version - Andres Bohren
###############################################################################

###############################################################################
# Azure AD Application
###############################################################################
#Microsoft Teams PowerShell Module 4.7.1-Preview with AzureAD App and Certificate Authentication
#https://blog.icewolf.ch/archive/2022/09/28/microsoft-teams-powershell-module-4-7-1-preview-with-azuread.aspx
<#
Requirements:
- Azure AD Application
- Self Signed Certificate (in Current User CertStore and uploaded to the AzureAD App)

Application Permissions:
- User.Read.All
- Group.ReadWrite.All
- AppCatalog.ReadWrite.All
- TeamSettings.ReadWrite.All
- Channel.Delete.All
- ChannelSettings.ReadWrite.All
- ChannelMember.ReadWrite.All

Azure AD App needs to be added to the Azure AD Role
- Skype for Business Administrators
#>

###############################################################################
# Use Self Signed Certificate to Authenticate
# Needs MicrosoftTeams 4.7.1-Preview PowerShell Module
###############################################################################
$AppID = "93b64305-ea5b-41f2-be0f-a2235fb91480" #DemoTeamsPS
$TenantId = "icewolfch.onmicrosoft.com"
$CertificateThumbprint = "4F1C474F862679EC35650824F73903041E1E5742"

Import-Module MicrosoftTeams
Connect-MicrosoftTeams -ApplicationId $AppID -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint

###############################################################################
# Use PFX and the Certificate Parameter
# Needs MicrosoftTeams 4.9.3 PowerShell Module
###############################################################################
$AppID = "93b64305-ea5b-41f2-be0f-a2235fb91480" #DemoTeamsPS
$TenantId = "icewolfch.onmicrosoft.com"
$PFXPassword = ConvertTo-SecureString -String "YourPFXPassword" -Force -AsPlainText
$PFX = Get-PfxData -FilePath "C:\GIT_WorkingDir\O365Powershell3.pfx" -Password $PFXPassword
$Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$Certificate = $PFX.EndEntityCertificates[0]

Import-Module MicrosoftTeams
Connect-MicrosoftTeams -ApplicationId $AppID -TenantId $TenantId -Certificate $Certificate