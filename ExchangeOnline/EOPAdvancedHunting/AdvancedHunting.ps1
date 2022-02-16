###############################################################################
# MessageTrace
###############################################################################
Get-MessageTrace -SenderAddress linkedin@e.linkedin.com
$MT = Get-MessageTrace -SenderAddress linkedin@e.linkedin.com -StartDate (Get-Date).AddDays(-10) -EndDate (Get-Date)
$MT[0] | Format-List
$MT

###############################################################################
# HistoricalSearch
###############################################################################
Start-HistoricalSearch -ReportTitle "Trace Runbook" -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date) -ReportType MessageTrace -SenderAddress admin@runbook.icewolf.ch -NotifyAddress a.bohren@icewolf.ch
Get-HistoricalSearch
Get-HistoricalSearch -JobId 1d24c703-1773-4c7d-86cd-be1a6937f7b9 | Format-List SubmitDate, CompletionDate
Stop-HistoricalSearch
 

###############################################################################
# Compliance Search
###############################################################################
Connect-IPPSSession -WarningAction SilentlyContinue
$Query = "(Subject: 'alert')" 
$Query = "(Received:4/13/2016..4/14/2016) AND (Subject:'Action required')"
$Query = "(From:andres.bohren@gmail.com) AND (Subject:'Test')"
$Query = "(c:c)(from=linkedin@e.linkedin.com)(to=a.bohren@icewolf.ch)"
$Query = "(from=linkedin@e.linkedin.com) AND (to=a.bohren@icewolf.ch)"
New-ComplianceSearch -ContentMatchQuery $Query -Name "MySearchName3" -Description "MySearchDescription3" -ExchangeLocation All
Get-ComplianceSearch

#Purge to Recoverable Items for the User
New-ComplianceSearchAction -SearchName "Remove Phishing Message" -Purge -PurgeType SoftDelete
Get-ComplianceSearchAction

#Purge to Exchange Dumpster
New-ComplianceSearchAction -SearchName "Remove Phishing Message" -Purge -PurgeType SoftDelete
Get-ComplianceSearchAction

#Remove ComplianceSearch / ComplianceSearchAction
Remove-ComplianceSearch
Remove-ComplianceSearchAction

###############################################################################
# Hash mit PowerShell
###############################################################################
#FileHash
Get-FileHash C:\GIT_WorkingDir\GitHub_PowerShellScripts\ExchangeOnline\EOP_Unsigned.zip -Algorithm SHA256
