# Install Modules
Install-PSResource -Name Az -Scope CurrentUser
Install-PSResource -Name Az.Communication -Scope CurrentUser

# Connect-AzAccount
$SubscriptionID = "fb33f2b7-e082-4028-9fa2-98d7ecaaa105"
Connect-AzAccount -Tenant icewolfch.onmicrosoft.com -Subscription $SubscriptionID

# Create Resource Group
$RGName = "RG_ACS"
$Location = "westeurope"
New-AzResourceGroup -Name $RGName -Location $Location

# Create ECS Service
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
$DataLocation = "Switzerland"
New-AzEmailService -Name $EmailServiceName -ResourceGroupName $ResourceGroup -Location "global" -DataLocation $DataLocation

# Get ECS Service
$RGName = "RG_ACS"
Get-AzEmailService -ResourceGroup $RGName

# Add DomainManagement
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
New-AzEmailServiceDomain -ResourceGroupName $RGName -EmailServiceName $EmailServiceName -Name AzureManagedDomain -DomainManagement AzureManaged


# Custom Domain
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
$CustomDomain = "ecs.icewolf.ch"
New-AzEmailServiceDomain -ResourceGroupName $RGName -EmailServiceName $EmailServiceName -Name $CustomDomain -DomainManagement "CustomerManaged"

# Get CustomDomain 
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
Get-AzEmailServiceDomain -ResourceGroup $RGName -EmailServiceName $EmailServiceName


# Variables
$RGName = "RG_ACS"
$DnsZoneName = "ecs.icewolf.ch"
$Location = "global"

# Create DNS Zone
$DnsZone = New-AzDnsZone -Name $DnsZoneName -ResourceGroupName $RGName

$DNSZone
$DnsZone.NameServers

# Add TXT Records (ms-domain-verification / SPF)
$DnsRecordConfig = @(
	New-AzDnsRecordConfig -Value "ms-domain-verification=5b84b425-eb9f-4ac1-adc2-9be1a6c83a62"
	New-AzDnsRecordConfig -Value "v=spf1 include:spf.protection.outlook.com -all"
)
New-AzDnsRecordSet -Name "@" -RecordType TXT -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig

# SPF TXT
$DnsRecordConfig = New-AzDnsRecordConfig -Value "v=spf1 include:spf.protection.outlook.com -all"
New-AzDnsRecordSet -Name "@" -RecordType TXT -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig


# DKIM Selector 1
$DnsRecordConfig = New-AzDnsRecordConfig -Cname "selector1-azurecomm-prod-net._domainkey.azurecomm.net"
New-AzDnsRecordSet -Name "selector1-azurecomm-prod-net._domainkey" -RecordType CNAME -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig

# DKIM Selector 2
$DnsRecordConfig = New-AzDnsRecordConfig -Cname "selector2-azurecomm-prod-net._domainkey.azurecomm.net"
New-AzDnsRecordSet -Name "selector2-azurecomm-prod-net._domainkey" -RecordType CNAME -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig


$RGName = "RG_ACS"
$DnsZoneName = "ecs.icewolf.ch"

# DMARC
$DnsRecordConfig = New-AzDnsRecordConfig -Value "v=DMARC1; p=reject; sp=reject; "
New-AzDnsRecordSet -Name "_dmarc" -RecordType TXT -ZoneName $DnsZoneName -ResourceGroupName $RGName -Ttl 3600 -DnsRecords $DnsRecordConfig

# Create Delegation in parent Zone
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


# Create ACS
$ACSName = "IcewolfACS"
$RGName = "RG_ACS"
$DataLocation = "Switzerland"
New-AzCommunicationService -ResourceGroupName $RGName -Name $ACSName -DataLocation $DataLocation -Location Global

# Get ACS
Get-AzCommunicationService -ResourceGroupName $RGName

# Connect ECS with ACS
$ACSName = "IcewolfACS"
$EmailServiceName = "IcewolfECS"
$RGName = "RG_ACS"
New-AzEmailServiceDomain -Name $ACSName -EmailServiceName $EmailServiceName -ResourceGroupName $RGName -DomainManagement CustomerManaged


# Send Email
# https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email?tabs=windows%2Cconnection-string%2Csend-email-and-get-status-async%2Casync-client&pivots=platform-powershell
Connect-AzAccount -AuthScope AzureCommunicationEmailEndpointResourceId

$Endpoint = "https://icewolfacs.switzerland.communication.azure.com"

# Send Mail
$emailRecipientTo = @(
   @{
        Address = "<a.bohren@icewolf.ch>"
        DisplayName = "Andres Bohren"
    }
)

$message = @{
    ContentSubject = "Test Email"
    RecipientTo = @($emailRecipientTo)  # Array of email address objects
    SenderAddress = '<donotreply@ecs.icewolf.ch>'
	ReplyTo = @('andres.bohren@gmail.com')
    ContentPlainText = "This is the first email from ACS - Azure PowerShell"    
}

Send-AzEmailServicedataEmail -Message $Message -endpoint $Endpoint


https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email-smtp/smtp-authentication?tabs=built-in-role
Communication and Email Service Owner


# Reister SMTP Username
$ACSName = "IcewolfACS"
$RGName = "RG_ACS"
$AppID = "2fcec215-1585-4634-8965-de3a7782c6c9"
$TenantID = "46bbad84-29f0-4e03-8d34-f6841a5071ad"
New-AzCommunicationServiceSmtpUsername -CommunicationServiceName $ACSName -ResourceGroupName $RGName -SmtpUsername "smtpuser1" -EntraApplicationId $AppId -TenantId $TenantId -Username "app1@ecs.icewolf.ch"


$Password = ConvertTo-SecureString -AsPlainText -Force -String 'YourAppClientSecret'
$Cred = New-Object -TypeName PSCredential -ArgumentList 'app1@ecs.icewolf.ch', $Password
Send-MailMessage -From 'donotreply@ecs.icewolf.ch' -To 'a.bohren@icewolf.ch' -Subject 'Test mail' -Body 'test' -SmtpServer 'smtp.azurecomm.net' -Port 587 -Credential $Cred -UseSsl