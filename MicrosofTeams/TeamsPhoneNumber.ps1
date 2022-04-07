###############################################################################
# Add / Remove Phone Number in MicrosoftTeams
# Needs to be implemented in March 2022 
# The retirement is planned to begin in early April and be complete by mid-April
# 07.04.2022 V0.1 - Initial Version - Andres Bohren
###############################################################################

Function Set-TeamsPhoneNumber
{
    Param(
        [Parameter(Mandatory=$true)][String]$UPN,
		[Parameter(Mandatory=$true)][String]$PhoneNumber,
		[Parameter(Mandatory=$true)][String]$PhoneNumberType
    )	
	
	#Check Licenses of User 
	$Licenses = Get-MgUserLicenseDetail -UserId $UPN

	#Check Teams License
	$TeamsLicense = $Licenses | where {$_.ServicePlans.ServicePlanname -match "TEAMS1"}
	If ($Null -eq $TeamsLicense)
	{
		Throw "User has no Teams License"
	} 

	#Check PhoneSystem
	$PhoneSystemLicense = $Licenses | where {$_.SkuId -eq "e43b5b99-8dfb-405f-9987-dc307f34bcbd"} #PhoneSystem / MCOEV
	If ($Null -eq $PhoneSystemLicense)
	{
		Write-Host "Adding PhoneSystem License" -ForeGroundColor Green
		Set-MgUserLicense -UserId $UPN -AddLicenses @{SkuId = 'e43b5b99-8dfb-405f-9987-dc307f34bcbd'} -RemoveLicenses @() | Out-Null #PhoneSystem / MCOEV
	} else {
		Write-Host "PhoneSystem License found"
		[Bool]$NoWait = $true
	}

	Do
	{
		$Licenses = Get-MgUserLicenseDetail -UserId $UPN
		$PhoneSystemLicense = $Licenses | where {$_.SkuId -eq "e43b5b99-8dfb-405f-9987-dc307f34bcbd"} #PhoneSystem / MCOEV
		If ($Null -eq $PhoneSystemLicense)
		{
			Write-Host "No PhoneSystem License found" -ForeGroundColor Yellow
		}
		Start-Sleep -Seconds 5
	} while ($Null -eq $PhoneSystemLicense)
	
	If ($NoWait -eq $true)
	{
		#Do Nothing
	} else {
		Write-Host "Wait 120 Seconds before assigning Number"
		Start-Sleep -Seconds 120
	}

	###############################################################################
	# Set-CsPhoneNumberAssignment
	# https://docs.microsoft.com/en-us/powershell/module/teams/set-csphonenumberassignment?view=teams-ps
	###############################################################################
	Set-CsPhoneNumberAssignment -Identity $UPN -PhoneNumber $PhoneNumber -PhoneNumberType $PhoneNumberType

}

Function Remove-TeamsPhoneNumber
{
    Param(
        [Parameter(Mandatory=$true)][String]$UPN
	)


	$CsUser = Get-CsOnlineUser -Identity m.muster@icewolf.ch
	If ($CsUser.EnterpriseVoiceEnabled -eq $True)
	{
		###############################################################################
		# Remove-CsPhoneNumberAssignment
		# https://docs.microsoft.com/en-us/powershell/module/teams/remove-csphonenumberassignment?view=teams-ps
		###############################################################################
		Remove-CsPhoneNumberAssignment -Identity $UPN -RemoveAll
		
		#Remove PhoneSystem / MCOEV License
		Write-Host "Remove PhoneSystem / MCOEV License"
		Set-MgUserLicense -UserId $UPN -AddLicenses @() -RemoveLicenses @('e43b5b99-8dfb-405f-9987-dc307f34bcbd') | Out-Null
	} else {
		Write-Host "EnterpriseVoiceEnabled is already False"
	}
}


###############################################################################
# Main Script 
###############################################################################
#Needs the following Roles
# - User Administrator
# - Teams Administrator
Connect-MicrosoftTeams
Connect-MgGraph -Scopes User.ReadWrite.All
Set-TeamsPhoneNumber -UPN m.muster@icewolf.ch -PhoneNumber "+41215553975" -PhoneNumberType "DirectRouting"
Get-CsOnlineUser -Identity m.muster@icewolf.ch | fl EnterpriseVoiceEnabled, HostingProvider, *LineUri, *tel*
Remove-TeamsPhoneNumber -UPN m.muster@icewolf.ch


<#
###############################################################################
# Basics
###############################################################################

#Get License from User
Connect-MgGraph -Scopes User.ReadWrite.All
Get-MgUserLicenseDetail -UserId m.muster@icewolf.ch
$Licenses = Get-MgUserLicenseDetail -UserId a.bohren@icewolf.ch
$Licenses = Get-MgUserLicenseDetail -UserId m.muster@icewolf.ch

$Licenses
$Licenses[0].ServicePlans

#Teams License
$Licenses | where {$_.ServicePlans.ServicePlanname -match "TEAMS1"}

#PhoneSystem
$Licenses | where {$_.SkuId -eq "e43b5b99-8dfb-405f-9987-dc307f34bcbd"}

###############################################################################
# Add PhoneSystem / MCOEV License
###############################################################################
Set-MgUserLicense -UserId m.muster@icewolf.ch -AddLicenses @{SkuId = 'e43b5b99-8dfb-405f-9987-dc307f34bcbd'} -RemoveLicenses @() #PhoneSystem / MCOEV

###############################################################################
# Get-CsOnlineUser
# https://docs.microsoft.com/en-us/powershell/module/skype/get-csonlineuser?view=skype-ps
###############################################################################
Connect-MicrosoftTeams
Get-CsOnlineUser -Identity m.muster@icewolf.ch | fl EnterpriseVoiceEnabled, *HostingProvider, HostedVoiceMail, *um*, *LineUri

###############################################################################
# Set-CsPhoneNumberAssignment
# https://docs.microsoft.com/en-us/powershell/module/teams/set-csphonenumberassignment?view=teams-ps
###############################################################################
Set-CsPhoneNumberAssignment -Identity m.muster@icewolf.ch -PhoneNumber +41215553975 -PhoneNumberType DirectRouting

###############################################################################
# Get-CsOnlineUser
# https://docs.microsoft.com/en-us/powershell/module/skype/get-csonlineuser?view=skype-ps
###############################################################################
Get-CsOnlineUser -Identity m.muster@icewolf.ch | fl EnterpriseVoiceEnabled, *HostingProvider, HostedVoiceMail, *um*, *LineUri

###############################################################################
# Remove-CsPhoneNumberAssignment
# https://docs.microsoft.com/en-us/powershell/module/teams/remove-csphonenumberassignment?view=teams-ps
###############################################################################
Remove-CsPhoneNumberAssignment -Identity m.muster@icewolf.ch -RemoveAll

###############################################################################
# Remove PhoneSystem / MCOEV License
###############################################################################
Set-MgUserLicense -UserId m.muster@icewolf.ch -AddLicenses @() -RemoveLicenses @('e43b5b99-8dfb-405f-9987-dc307f34bcbd') #PhoneSystem / MCOEV
#>
