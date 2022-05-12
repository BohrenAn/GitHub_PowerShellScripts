###############################################################################
# Get Emailadresses from TeamsChannel
# 25.04.2021 V0.1 Initial Version - Andres Bohren
###############################################################################
#Channel.ReadBasic.All
#ChannelSettings.Read.All
#Group.Read.All
$APPID = "05be746b-7e2f-4e57-b99d-e793a7535d08"
$CertificateThumbprint = "4F1C474F862679EC35650824F73903041E1E5742" #O365Powershell2.cer
$TenantID = "icewolfch.onmicrosoft.com"
Connect-MgGraph -TenantId $TenantID -AppId $APPID -CertificateThumbprint $CertificateThumbprint

#Connect-MgGraph -TenantId icewolfch.onmicrosoft.com -Scopes Channel.ReadBasic.All, ChannelSettings.Read.All, ChannelSettings.ReadWrite.All #, Group.Read.All**, Group.ReadWrite.All**, Directory.Read.All**, Directory.ReadWrite.All**


#Get-Team
Write-Host "Getting Teams..."
Connect-MicrosoftTeams
$StartDate = Get-Date
$TeamsArray = Get-Team
$EndDate = Get-Date
$TimeSpan = New-TimeSpan -Start $StartDate -End $EndDate
$TimeSpan 

$TeamsCount = $TeamsArray.count
Write-Host "Teams found: $TeamsCount"

#Create CSV File
$Path = $PSScriptRoot
$ShortDate = get-date -Format ("yyyyMMdd")
$Path = "$Path\TeamsChannelEmail_$ShortDate.csv"
If (Test-Path -Path $Path)
{
	Remove-Item -Path $Path -Confirm:$false
}
#CreateHeader
Add-Content -Path $Path "TeamsObjectId;TeamsDisplayName;ChannelDisplayName;ChannelEmail"

#Loop through Teams 
$Int = 0
Foreach ($Team in $TeamsArray)
{
	$Int = $Int + 1
	$DisplayName = $Team.DisplayName
	$GroupId = $Team.GroupId
	Write-Host "Working on: $DisplayName [$Int/$TeamsCount]" -ForeGroundColor Green
	
	#Loop through Channels
	$Channels = Get-MgTeamChannel -TeamId $GroupId
	Foreach ($Channel in $Channels)
	{
		$ChannelDisplayName = $Channel.DisplayName
		$ChannelEmail = $Channel.Email
		If ($ChannelEmail -ne "")
		{
			#Email found
			Write-Host "$ChannelDisplayName > $ChannelEmail"
			#Add to CSV File
			Add-Content -Path $Path "$GroupId;$DisplayName;$ChannelDisplayName;$ChannelEmail"
		}
	}
}
