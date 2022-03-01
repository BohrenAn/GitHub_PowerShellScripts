###############################################################################
# This Script checks all O365 Groups/Teams for the Setting AllowToAddGuests
# Version 1.0 - 23.02.2022 Initial Version - Andres Bohren
# Prevent guests from being added to a specific Microsoft 365 group or Microsoft Teams team
# https://docs.microsoft.com/en-us/microsoft-365/solutions/per-group-guest-access?view=o365-worldwide
###############################################################################
Connect-ExchangeOnline
Connect-AzureAD

$Groups = Get-UnifiedGroup -ResultSize Unlimited
$Groups.Count


Foreach ($Group in $Groups)
{
	$GroupName = $Group.DisplayName
	$GroupID = $Group.ExternalDirectoryObjectId
	#Write-Host "Working on: $GroupName > $GroupID" -ForegroundColor Green
	
	#https://docs.microsoft.com/en-us/microsoft-365/solutions/per-group-guest-access?view=o365-worldwide
	$ObjectSetting = Get-AzureADObjectSetting -TargetObjectId $groupID -TargetType Groups
	If ($ObjectSetting -ne $Null)
	{
		#$Values = $ObjectSetting.Values
		#Write-Host "Values: $Values"
		
		If ($ObjectSetting.Values.name -eq "AllowToAddGuests")
		{
			If ($ObjectSetting.Values.Value -eq "False")
			{
				Write-Host "Working on: $GroupName > $GroupID" -ForegroundColor Green
				Write-Host "AllowToAddGuests FALSE" -ForegroundColor Yellow
			} else {
				Write-Host "Working on: $GroupName > $GroupID" -ForegroundColor Green
				Write-Host "AllowToAddGuests TRUE" -ForegroundColor Cyan
			}
		} 
	}
}