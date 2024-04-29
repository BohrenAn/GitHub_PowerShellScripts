###############################################################################
# List Fido2 Keys in M365 for all Users
# 23.04.2024 - V1.0 - Initial Version - Andres Bohren
###############################################################################

Connect-MgGraph -Scopes User.Read.All, UserAuthenticationMethod.Read.All  -NoWelcome
$EntraUsers = Get-MgUser -All
$EntraUsersCount = $EntraUsers.Count
Write-Host "Users found: $EntraUsersCount" 

#Create ListObject
$FIDO2List = [System.Collections.Generic.List[object]]::new()

#Loop through Users
$INT = 0
Foreach ($EntraUser in $EntraUsers)
{
	$INT = $INT + 1
	$UPN = $entraUser.UserPrincipalName
	Write-Host "Working on: $UPN [$INT/$EntraUsersCount]" -ForegroundColor Green
	$Fido2Methods = Get-MgUserAuthenticationFido2Method -UserId $UPN
	
	#If FidoMethods found
	If ($Null -ne $Fido2Methods)
	{
		Write-Host "FIDO2 found" -ForegroundColor Cyan
		Foreach ($Fido2Method in $Fido2Methods)
		{
			$FIDOObject = [PSCustomObject]@{
			UserPrincipalName 	= $UPN
			AAGUID				= $Fido2Method.AAGUID
			Model				= $Fido2Method.Model
			AttestationLevel	= $Fido2Method.AttestationLevel
			}
			
			#Add to ListObject
			$FIDO2List.Add($FIDOObject)
		}
	}
}

#Show Fido Authentication Methods
$FIDO2List 

#Export to CSV
$FIDO2List | Export-CSV -Path C:\Temp\Fido2List.csv -Encoding UTF8 -NoTypeInformation