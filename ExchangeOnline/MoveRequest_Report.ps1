###############################################################################
# Moverequest Report Details
# 02.07.2023 Andres Bohren
###############################################################################
$MRS = @()
$MR = Get-MoveRequest | Where-Object {$_.Status -match "InProgress"} 
Foreach ($MoveRequest in $MR)
{ 
	$MRS += Get-MoveRequestStatistics -Identity $Moverequest -IncludeReport
}

ForEach ($Stat in $MRS)
{
	$DisplayName = $Stat.DisplayName
	$StatusDetail = $Stat.StatusDetail
	$PercentComplete = $Stat.PercentComplete
	$Report = $Stat.Report
	$LastMessage = $Report.Entries[$Report.Entries.Count -1].Message
	$LastLocalizedString = $Report.Entries[$Report.Entries.Count -1].LocalizedString
	$LastFailureMessage = $Report.Failures[$Report.Failures.Count -1].Message
	$LastFailureInnerException = $Report.Failures[$Report.Failures.Count -1].InnerException
	
	
	Write-Host "$DisplayName > $StatusDetail > $PercentComplete" -ForegroundColor Green
	Write-Host "LastMessage: $LastMessage"
	Write-Host "LastLocalizedString: $LastLocalizedString"
	Write-Host "LastFailureMessage: $LastFailureMessage"
	Write-Host "LastFailureInnerException: $LastFailureInnerException"
}