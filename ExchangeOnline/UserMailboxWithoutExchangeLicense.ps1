###############################################################################
# Check for UserMailbox without Exchange Licenses
# 22.02.2023 - Initial Version - Andres Bohren
###############################################################################
Connect-MgGraph -Scope User.Read.All
Connect-ExchangeOnline -ShowBanner:$False

$Users = Get-MgUser -All -Filter "userType eq 'member'"
Foreach ($User in $Users)
{
	$UPN = $User.UserPrincipalName
	#Write-Host "Working on: $UPN" -ForeGroundColor Green
	$Licenses = Get-MgUserLicenseDetail -UserId $UPN
	#$E3 = $Licenses.SkuPartNumber -contains "ENTERPRISEPACK"
	$ExchangeLicense = $Null
	$ExchangeLicense = $Licenses.ServicePlans | Where-Object {$_.ServicePlanName -match "EXCHANGE" -and $_.ProvisioningStatus -eq "Success" -and $_.AppliesTo -eq "User"}
	$Mailbox = Get-Mailbox -Identity $UPN -RecipientTypeDetails UserMailbox -ErrorAction SilentlyContinue
	
	If ($Null -ne $Mailbox -And $Null -eq $ExchangeLicense)
	{
		Write-Host "UPN: $UPN has UserMailbox but no ExchangeLicense" -ForeGroundColor Yellow
	}
}

Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph