###############################################################################
# Based on the Scrirpt from Microsoft
# SearchAuditLog.ps1
# https://learn.microsoft.com/en-us/purview/audit-log-search-script
###############################################################################

#Connect to Exchange Online
$ConnectionInfo = Get-ConnectionInformation
If ($Null -eq $ConnectionInfo)
{
	Write-Host "Connect to Exchange Online"
	Connect-ExchangeOnline -ShowBanner:$false
}

#Modify the values for the following variables to configure the audit log search.
$Start = Get-Date
$logFile = "C:\Temp\AuditLogSearchLog.txt"
$outputFile = "C:\Temp\AuditLogRecords.csv"
[DateTime]$StartDate = [datetime]::parseexact("2024-04-01", "yyyy-MM-dd", $null) #[DateTime]::UtcNow.AddDays(-90)
[DateTime]$EndDate = [datetime]::parseexact("2024-06-01", "yyyy-MM-dd", $null) #[DateTime]::UtcNow.AddDays(-20)
#$record = "AzureActiveDirectory"
$resultSize = 5000
$intervalMinutes = 60

#Start script
[DateTime]$currentStart = $StartDate
[DateTime]$currentEnd = $EndDate

Function Write-LogFile ([String]$Message)
{
    $final = [DateTime]::Now.ToUniversalTime().ToString("s") + ":" + $Message
    $final | Out-File $logFile -Append
}

Write-LogFile "BEGIN: Retrieving audit records between $($startdate) and $($enddate), RecordType=$record, PageSize=$resultSize."
Write-Host "Retrieving audit records for the date range between $($startdate) and $($enddate), RecordType=$record, ResultsSize=$resultSize"

$totalCount = 0
while ($true)
{
    $currentEnd = $currentStart.AddMinutes($intervalMinutes)
    if ($currentEnd -gt $EndDate)
    {
        $currentEnd = $EndDate
    }

    if ($currentStart -eq $currentEnd)
    {
        break
    }

    $sessionID = [Guid]::NewGuid().ToString() + "_" +  "ExtractLogs" + (Get-Date).ToString("yyyyMMddHHmmssfff")
    Write-LogFile "INFO: Retrieving audit records for activities performed between $($currentStart) and $($currentEnd)"
    Write-Host "Retrieving audit records for activities performed between $($currentStart) and $($currentEnd)"
    $currentCount = 0

    $sw = [Diagnostics.StopWatch]::StartNew()
    do
    {
        $results = Search-UnifiedAuditLog -StartDate $currentStart -EndDate $currentEnd -Operations MailItemsAccessed -SessionId $sessionID -SessionCommand ReturnLargeSet -ResultSize $resultSize

        if (($results | Measure-Object).Count -ne 0)
        {
            $results | export-csv -Path $outputFile -Append -NoTypeInformation

            $currentTotal = $results[0].ResultCount
            $totalCount += $results.Count
            $currentCount += $results.Count
            Write-LogFile "INFO: Retrieved $($currentCount) audit records out of the total $($currentTotal)"

            if ($currentTotal -eq $results[$results.Count - 1].ResultIndex)
            {
                $message = "INFO: Successfully retrieved $($currentTotal) audit records for the current time range. Moving on!"
                Write-LogFile $message
                Write-Host "Successfully retrieved $($currentTotal) audit records for the current time range. Moving on to the next interval." -foregroundColor Yellow
                ""
                break
            }
        }
    }
    while (($results | Measure-Object).Count -ne 0)

$currentStart = $currentEnd
}

Write-LogFile "END: Retrieving audit records between $($start) and $($end), RecordType=$record, PageSize=$resultSize, total count: $totalCount."
Write-Host "Script complete! Finished retrieving audit records for the date range between $($startdate) and $($enddate). Total count: $totalCount" -foregroundColor Green
$End = Get-Date
$Timespan = New-Timespan -Start $Start -End $End
$Timespan