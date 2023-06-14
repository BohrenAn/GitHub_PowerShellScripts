###############################################################################
# Report Teams VoiceMail Settings
# 14.06.2023 - Initial Script - Andres Bohren
# https://blog.icewolf.ch/archive/2022/06/25/microsoft-teams-voicemail-settings-for-users-and-admins/
###############################################################################

#Connect-MicrosoftTeams
Connect-MicrosoftTeams

#Get all Teams users
$CSUsers = Get-CsOnlineUser -ResultSize 0 | Where-Object {$_.InterpretedUserType -eq "HybridOnlineTeamsOnlyUser"}

Set-Content -Path .\TeamsVoiceMail.csv -Value "UPN;VoicemailEnabled;PromptLanguage"

$INT = 0
Foreach ($CSUser in $CSUsers)
{
	$INT = $INT +1
	$UPN = $CSUser.UserPrincipalName
	Write-Host "Working on: $UPN [$INT]"

	#Get VoiceMail User
	$VoiceMailSettings = Get-CsOnlineVoicemailUserSettings -Identity $UPN
	$VoicemailEnabled = $VoiceMailSettings.VoicemailEnabled
	$PromptLanguage = $VoiceMailSettings.PromptLanguage

	#Save to VSV
	Add-Content -Path .\TeamsVoiceMail.csv -Value "$UPN;$VoicemailEnabled;$PromptLanguage"

}