###############################################################################
# DeployStaticWebApp.ps1
# 2024-02-02 - Andres Bohren - Initial version
###############################################################################
#Requires -Version 7

#Variables
$SubscriptionId = "17266dd0-370e-49b6-a30f-7329ab2ea32e"
$ResourceGroupName = "prod-MTA-STS"
#$Location = "switzerlandnorth"
$Location = "westeurope"
$Tenant = "tenant.onmicrosoft.com"


#Get Domain
$Domain = Read-Host -Prompt 'Enter the domain name (domain.tld)'
$DomainOnly = $Domain.Split(".")[0]
$MTASTSDomain = "mta-sts.$Domain"

#Check MX record
$MXRecord = Resolve-DnsName -Name $Domain -Type MX -ErrorAction SilentlyContinue
If ($null -eq $MXRecord){
	Write-Host "NO MX record found for $Domain" -ForegroundColor Red
	Exit
} else {
	Write-Host "MX record found for $Domain" -ForegroundColor Green
	$MXRecord
}

#Check NS record
$NS = Resolve-DnsName -Name $Domain -Type NS -ErrorAction SilentlyContinue
If ($Null -eq $NS){
	Write-Host "NO NS record found for $Domain" -ForegroundColor Red
	Exit
} else {
	Write-Host "NS record found for $Domain" -ForegroundColor Green
	$NS | ft Name,Type,TTL,NameHost
}


#Connect to Azure
$AZContext = Get-AzContext
If ($null -eq $AZContext)
{
	Write-Host "Connecting to Azure..."
	Connect-AzAccount -Tenant $Tenant -Subscription $SubscriptionId | Out-Null
} else {
	If ($AZContext.Subscription.Id -ne $SubscriptionId)
	{
		Write-Host "Disconnecting from current Azure subscription..."
		Disconnect-AzAccount | Out-Null
		Write-Host "Connecting to Azure..."
		Connect-AzAccount -Tenant sbb.onmicrosoft.com -Subscription $SubscriptionId | Out-Null
	} else {
		Write-Host "Already connected to Azure..."
	}
}

#Get-AzResourceGroup | Format-Table ResourceGroupName
#Get-AzResourceGroup $ResourceGroupName | Format-List

$SWAName = "MTA-STS-$DomainOnly"

#Check if Static Web App (SWA) exists
$SWA = Get-AzStaticWebApp -Name $SWAName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

If ($null -ne $SWA){
	Write-Host "Static Web App $SWAName already exists in Resource Group $ResourceGroupName"
} else {
	Write-Host "Creating Static Web App $SWAName in Resource Group $ResourceGroupName" 
	$SWA = New-AzStaticWebApp -Name $SWAName -ResourceGroupName $ResourceGroupName -Location $Location -SkuName 'Standard' #-RepositoryUrl $RepoURL

}

# DNS Records
Write-Host "DNS Records for $Domain" -ForegroundColor Green
$DefaultHostname = $swa.DefaultHostname
$ID = get-date -UFormat %Y%m%dT%H0000
Write-Host "_mta-sts.$Domain TXT v=STSv1; id=$ID;" -ForegroundColor Yellow
Write-Host "$MTASTSDomain CNAME $DefaultHostname" -ForegroundColor Yellow
Write-Host "_smtp._tls.$Domain TXT v=TLSRPTv1; rua=mailto:tlsrptrecipient@domain.tld" -ForegroundColor Yellow

#Get DevOps Variables
Write-Host "Variables for Azure DevOps" -ForegroundColor Green
$Secrets = Get-AzStaticWebAppSecret -Name $SWAName -ResourceGroupName $ResourceGroupName
$APIKey = $Secrets.Property.Values

$UppercaseDomain = $DomainOnly.ToUpper()
$SWAPrefix = $DefaultHostname.Split(".")[0]
Write-Host "Create Variablegroup: AZURE_STATIC_WEB_APPS_API_TOKEN_$UppercaseDomain-variable-group" -ForegroundColor Yellow
Write-Host "Create Variable: AZURE_STATIC_WEB_APPS_API_TOKEN_$SWAPrefix" -ForegroundColor Yellow
Write-Host "Create Value: $APIKey" -ForegroundColor Yellow


<#
#Add Custom Domain
#Write-Host "Adding Custom Domain $MTASTSDomain to Static Web App $SWAName"
#New-AzStaticWebAppCustomDomain -Name $SWAName -ResourceGroupName $ResourceGroupName -DomainName $MTASTSDomain
#New-AzStaticWebAppCustomDomain -Name "MTA-STS-transicura" -ResourceGroupName $ResourceGroupName -DomainName "mta-sts.transsicura.ch"

### Check and Delete Static Web App (SWA)
$SWA = Get-AzStaticWebApp -ResourceGroupName $ResourceGroupName
$SWA
Remove-AzStaticWebApp -Name "MTA-STS-transicura" -ResourceGroupName $ResourceGroupName
#>
