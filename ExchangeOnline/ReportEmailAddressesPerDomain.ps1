###############################################################################
# Report EmailAddresses and PrimaryEmailaddress per AcceptedDomain
# 2023.01.25 - V1.0 - Andres Bohren
###############################################################################

#Connect-ExchangeOnline
If ($Null -eq $(Get-ConnectionInformation))
{
	Write-Host "Connect-ExchangeOnline" -ForegroundColor Green
	Connect-ExchangeOnline -ShowBanner:$false
}

#Get-AcceptedDomain
Write-Host "Getting AcceptedDomains..." -ForegroundColor Green
$AcceptedDomains = Get-AcceptedDomain

Write-Host "Getting Mailboxes..." -ForegroundColor Green
$Mailboxes = Get-Mailbox -ResultSize Unlimited 

#Loop through AcceptedDomains
$Results = @() 
$INT = 0 
Foreach ($AcceptedDomain in $AcceptedDomains) 
{ 
	$INT = $INT + 1 
	$Domain = $AcceptedDomain.DomainName 
	Write-Host "Working on Domain: $Domain [$INT]" -ForegroundColor Green 

	#Additional EmailAddresses
	[Array]$RecipientAddress = $Mailboxes| where {$_.EmailAddresses -like "*@$Domain"}
	$RecipientCount = $RecipientAddress.Count 
	Write-Host "EmailAddressesCount: $RecipientCount" 

	#PrimaryEmailaddress
	[Array]$PrimaryRecipients = $Mailboxes| where {$_.PrimarySMTPAddress -like "*@$Domain"}
	$PrimaryRecipientCount = $PrimaryRecipients.Count 
	Write-Host "PrimaryAddressCount: $PrimaryRecipientCount" 

	#Create PSCustomObject
	$myObject = [PSCustomObject]@{ 
	Domain     = $domain 
	EmailAddresses = $RecipientCount 
	PrimaryEmailaddress  = $PrimaryRecipientCount 
	} 

	#Add to Results Array
	$Results += $myObject
}
$Results
$CSVPath = "$PSScriptRoot\EmailAddressesPerDomain.csv"
Write-Host "Exported to $CSVPath"
$Results | Export-Csv -Path "$PSScriptRoot\EmailAddressesPerDomain.csv" -NoTypeInformation