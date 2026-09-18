###############################################################################
# Setup ECS (Email Communication Service) in Azure
# This script sets up the Email Communication Service (ECS) in Azure, including the creation of the ECS service, custom domain, DNS zone, and domain verification.
# It also includes the creation of an Entra application for SMTP authentication.
# Version: 1.0 - Initial release - 2026-09-10 - Andres Bohren
###############################################################################

# Install Modules
Install-PSResource -Name Az -Scope CurrentUser
Get-InstalledPSResource -Name Az.Communication -Scope CurrentUser
Install-PSResource -Name Az.Communication -Scope CurrentUser
Get-InstalledPSResource -Name Az.Communication -Scope CurrentUser

# Connect-AzAccount
$SubscriptionID = "fb33f2b7-e082-4028-9fa2-98d7ecaaa105"
Connect-AzAccount -Tenant icewolfch.onmicrosoft.com -Subscription $SubscriptionID

# Create Resource Group
$RGName = "RG_ACS"
$Location = "westeurope"
New-AzResourceGroup -Name $RGName -Location $Location

###############################################################################
# Create ECS Service
###############################################################################
# Create ECS Service
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
$DataLocation = "Switzerland"
New-AzEmailService -Name $EmailServiceName -ResourceGroupName $RGName -Location "global" -DataLocation $DataLocation

# Get ECS Service
$RGName = "RG_ACS"
Get-AzEmailService -ResourceGroup $RGName

# Custom Domain
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
$CustomDomain = "ecs.icewolf.ch"
New-AzEmailServiceDomain -ResourceGroupName $RGName -EmailServiceName $EmailServiceName -Name $CustomDomain -DomainManagement "CustomerManaged"

# Get CustomDomain 
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
Get-AzEmailServiceDomain -ResourceGroup $RGName -EmailServiceName $EmailServiceName

# Get CustomDomain Verification Records
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
$ESD = Get-AzEmailServiceDomain -ResourceGroup $RGName -EmailServiceName $EmailServiceName
$ESD.VerificationRecord

###############################################################################
# Create DNS Zone for ECS Service
###############################################################################
# Create DNS Zone
$RGName = "RG_ACS"
$DnsZoneName = "ecs.icewolf.ch"
$Location = "global"
$DnsZone = New-AzDnsZone -Name $DnsZoneName -ResourceGroupName $RGName

# Name Servers for the DNS Zone
$DNSZone
$DnsZone.NameServers

# Add TXT Records (ms-domain-verification / SPF)
$DnsRecordConfig = @(
    New-AzDnsRecordConfig -Value "ms-domain-verification=5b84b425-eb9f-4ac1-adc2-9be1a6c83a62"
    New-AzDnsRecordConfig -Value "v=spf1 include:spf.protection.outlook.com -all"
)
New-AzDnsRecordSet -Name "@" -RecordType TXT -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig

# DKIM Selector 1
$DnsRecordConfig = New-AzDnsRecordConfig -Cname "selector1-azurecomm-prod-net._domainkey.azurecomm.net"
New-AzDnsRecordSet -Name "selector1-azurecomm-prod-net._domainkey" -RecordType CNAME -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig

# DKIM Selector 2
$DnsRecordConfig = New-AzDnsRecordConfig -Cname "selector2-azurecomm-prod-net._domainkey.azurecomm.net"
New-AzDnsRecordSet -Name "selector2-azurecomm-prod-net._domainkey" -RecordType CNAME -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig

# DMARC
$DnsRecordConfig = New-AzDnsRecordConfig -Value "v=DMARC1; p=reject; sp=reject; "
New-AzDnsRecordSet -Name "_dmarc" -RecordType TXT -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig

###############################################################################
# Create DNS Delegation in parent Zone
###############################################################################
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$RGName = "RG_Prod"
$Null = Set-AzContext -SubscriptionId $SubscriptionId

$DnsZoneName = "icewolf.ch"
$NsConfig = @()
foreach ($NS in $DnsZone.NameServers)
{
    $NsConfig += New-AzDnsRecordConfig -Nsdname $NS
}
New-AzDnsRecordSet -Name "ecs" -RecordType NS -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $NsConfig

###############################################################################
# Invoke Domain Verification for ECS Service
###############################################################################

# Switch to ECS Subscription
$SubscriptionID = "fb33f2b7-e082-4028-9fa2-98d7ecaaa105"
$Null = Set-AzContext -SubscriptionId $SubscriptionId

# Get CustomDomain 
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
Get-AzEmailServiceDomain -ResourceGroup $RGName -EmailServiceName $EmailServiceName

# Invoke DNS Verification
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
$CustomDomain = "ecs.icewolf.ch"
Invoke-AzEmailServiceInitiateDomainVerification -DomainName $CustomDomain -EmailServiceName $EmailServiceName -ResourceGroupName $RGName -VerificationType Domain
Invoke-AzEmailServiceInitiateDomainVerification -DomainName $CustomDomain -EmailServiceName $EmailServiceName -ResourceGroupName $RGName -VerificationType SPF
Invoke-AzEmailServiceInitiateDomainVerification -DomainName $CustomDomain -EmailServiceName $EmailServiceName -ResourceGroupName $RGName -VerificationType DKIM
Invoke-AzEmailServiceInitiateDomainVerification -DomainName $CustomDomain -EmailServiceName $EmailServiceName -ResourceGroupName $RGName -VerificationType DKIM2
#Invoke-AzEmailServiceInitiateDomainVerification -DomainName $CustomDomain -EmailServiceName $EmailServiceName -ResourceGroupName $RGName -VerificationType DMARC

# Get CustomDomain 
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
Get-AzEmailServiceDomain -ResourceGroup $RGName -EmailServiceName $EmailServiceName

###############################################################################
# Create ACS
###############################################################################
$ACSName = "IcewolfACS"
$RGName = "RG_ACS"
$DataLocation = "Switzerland"
New-AzCommunicationService -ResourceGroupName $RGName -Name $ACSName -DataLocation $DataLocation -Location Global

# Get ACS
$RGName = "RG_ACS"
Get-AzCommunicationService -ResourceGroupName $RGName

###############################################################################
# Connect ECS Domain to ACS
###############################################################################
$SubscriptionID = "fb33f2b7-e082-4028-9fa2-98d7ecaaa105"
$RGName = "RG_ACS"
$ECSName = "IcewolfECS"
$ACSName = "IcewolfACS"

$DomainResourceID = (Get-AzEmailServiceDomain -ResourceGroup $RGName -EmailServiceName $ECSName).Id
$URI = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$RGName/providers/Microsoft.Communication/CommunicationServices/$ACSName`?api-version=2023-03-31"
$Body = @"
{
    "properties": {
        "linkedDomains": ["$DomainResourceID"]
    }
}
"@
Invoke-AzRestMethod -Method Patch -Uri $URI -Payload $Body


# Get ACS
$RGName = "RG_ACS"
Get-AzCommunicationService -ResourceGroupName $RGName

###############################################################################
# Send Email with AZ PowerShell
###############################################################################
# Send Email
# https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email?tabs=windows%2Cconnection-string%2Csend-email-and-get-status-async%2Casync-client&pivots=platform-powershell

Connect-AzAccount -AuthScope AzureCommunicationEmailEndpointResourceId -Subscription "fb33f2b7-e082-4028-9fa2-98d7ecaaa105" -WarningAction SilentlyContinue
$Endpoint = "https://icewolfacs.switzerland.communication.azure.com"

# Recipient Information
$emailRecipientTo = @(
   @{
        Address = "<a.bohren@icewolf.ch>"
        DisplayName = "Andres Bohren"
    }
)

# Message Content
$message = @{
    ContentSubject = "Test Email"
    RecipientTo = @($emailRecipientTo)  # Array of email address objects
    SenderAddress = '<donotreply@ecs.icewolf.ch>'
    ReplyTo = @('andres.bohren@gmail.com')
    ContentPlainText = "This is the first email from ACS - Azure PowerShell"    
}

# Send Email
Send-AzEmailServicedataEmail -Message $Message -endpoint $Endpoint

###############################################################################
# SMTP Authentication Setup
###############################################################################
# https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email-smtp/smtp-authentication?tabs=built-in-role
# Azure Role:Communication and Email Service Owner

# Create Entra Application for SMTP Authentication
$AppName = "SMTPAuthApp"
$App = New-AzADApplication -DisplayName $AppName
$AppID = $App.AppID
$AppID

# Add Owner to the Entra Application
Connect-MgGraph -Scopes Application.ReadWrite.All -NoWelcome
$App = Get-MgApplication -Filter "displayName eq 'SMTPAuthApp'"
$User = Get-MgUser -UserId "a.bohren@icewolf.ch"
$params = @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.Id)"
}
New-MgApplicationOwnerByRef -ApplicationId $App.Id -BodyParameter $params

# Get Entra Application Policy
Connect-MgGraph -Scopes Policy.ReadWrite.ApplicationConfiguration
Get-MgPolicyAppManagementPolicy | ConvertTo-Json -Depth 20

# Exclude the Entra Application from the default app management policy
$PolicyID = (Get-MgPolicyAppManagementPolicy).Id
$App = Get-MgApplication -Filter "displayName eq 'SMTPAuthApp'"
$App.Id      # Object ID
$App.AppId   # Client ID

$URI = "https://graph.microsoft.com/beta/applications/$($App.Id)/appManagementPolicies/`$ref"
$Body = @{
    "@odata.id" = "https://graph.microsoft.com/beta/policies/appManagementPolicies/$PolicyId"
}
Invoke-MgGraphRequest -Method "POST" -Uri $URI -Body $Body

# Add ClientSecret to the Entra Application
$App = Get-MgApplication -Filter "appId eq '$AppID'"

$PasswordCredential = @{
    DisplayName = "SMTPPassword"
    EndDateTime = (Get-Date).AddYears(2)
}
$Secret = Add-MgApplicationPassword -ApplicationId $App.Id -PasswordCredential $PasswordCredential
$ClientSecret = $Secret.SecretText

# Create Service Principal for the Entra Application
$AppName = "SMTPAuthApp"
Get-AzADApplication -DisplayName $AppName  | New-AzADServicePrincipal

# Add Azure Permission "Communication and Email Service Owner" to Entra Application
$RGName = "RG_ACS"
$AppName = "SMTPAuthApp"

# Get the Service Principal Object ID from the App ID
$SP = Get-AzADApplication -DisplayName $AppName | Get-AzADServicePrincipal

# Assign the role on the ACS instance
$ACSID = (Get-AzCommunicationService -ResourceGroupName $RGName).id
New-AzRoleAssignment -ObjectId $($SP.Id) -RoleDefinitionName "Communication and Email Service Owner" -Scope $ACSID

# Register SMTP Username
$ACSName = "IcewolfACS"
$RGName = "RG_ACS"
$AppID = "1364a53d-5997-4f7f-8df4-e4ee34c86ce3"
$TenantID = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
New-AzCommunicationServiceSmtpUsername -CommunicationServiceName $ACSName -ResourceGroupName $RGName -SmtpUsername "donotreply" -EntraApplicationId $AppId -TenantId $TenantId -Username "donotreply@ecs.icewolf.ch"

# Send Authenticated Email
$Password = ConvertTo-SecureString -AsPlainText -Force -String "$ClientSecret"
$Cred = New-Object -TypeName PSCredential -ArgumentList "donotreply@ecs.icewolf.ch", $Password
Send-MailMessage -From "donotreply@ecs.icewolf.ch" -To "a.bohren@icewolf.ch" -Subject "Test mail" -Body "test" -SmtpServer "smtp.azurecomm.net" -Port 587 -Credential $Cred -UseSsl -WarningAction SilentlyContinue