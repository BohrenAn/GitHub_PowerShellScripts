###############################################################################
# Rename UPN from specific Mailbox Type
# 11.04.2022 V0.1 - Andres Bohren - Initial Version
###############################################################################
$Rooms = Get-Mailbox -RecipientTypeDetails RoomMailbox -Resultsize Unlimited
Foreach ($Room in $Rooms)
{
	$Email = $Room.PrimarySMTPAddress
	$Alias = $Room.Alias
	$UPN = $Room.UserPrincipalName
	Write-Host "Working on: $Email / $UPN" -ForegroundColor Green
	If ($UPN -match "corp.icewolf.ch")
	{
		Write-Host "Match found"
		$NewUPN = $UPN.Replace("corp.icewolf.ch","icewolf.ch")
		Write-Host "NewUPN: $NewUPN"
		Set-Mailbox -Identity $UPN -UserPrincipalName $NewUPN
	}
}