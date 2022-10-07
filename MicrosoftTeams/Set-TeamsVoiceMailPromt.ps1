###############################################################################
# Set Microsoft Teams Voicemail PromtLanguage based on msExchUserCulture
# 07.09.2022 V1.0 Initial Version - Andres Bohren
###############################################################################
Connect-MicrosoftTeams
Import-Module ActiveDirectory

$ShortDate = Get-Date -f "yyyyMMdd"
$CSVPath =  "$PSScriptRoot\TeamsVoicemailPromt_$ShortDate.csv"

$CSUsers = Get-CsOnlineUser -ResultSize 0 | Where-Object {$_.InterpretedUserType -eq "HybridOnlineTeamsOnlyUser"}
Write-Host "Users Found: $($CSUser.Count)"
$INT = 0
Foreach ($CSUser in $CSUsers)
{
	$INT = $INT + 1
	$UPN = $CSUser.UserPrincipalName
	Write-Host "Working On: $UPN [$INT]"
	
	#Set UserCulture for VoiceMailUserSettings
	$ADUser = Get-ADUser -LDAPFilter "(UserprincipalName=$upn)" -Properties msExchUserCulture                
	$msExchUserCulture = $ADUser.msExchUserCulture
	
	#Get and Change VoiceMailUserSettings
	$VoiceMailSettings = Get-CsOnlineVoicemailUserSettings -Identity $UPN
	$PromptLanguage = $VoiceMailSettings.PromptLanguage
	Write-Host "$UPN > $PromptLanguage > $msExchUserCulture"
	Add-Content -Path $CSVPath -Value "$UPN;$PromptLanguage;$msExchUserCulture"
	If ($msExchUserCulture -ne $null -or $msExchUserCulture -ne "")
	{
		If ($msExchUserCulture -eq "it-CH")
		{
			$msExchUserCulture = "it-IT"
		}
	Set-CsOnlineVoicemailUserSettings -Identity $UPN -PromptLanguage $msExchUserCulture
	}
}