###############################################################################
# Exchange Server commands
# Andres Bohren
###############################################################################

#Certificate On Connector
$cert = Get-ExchangeCertificate -Thumbprint <ThumbPrint>
$tlscertificatename = "<i>$($cert.Issuer)<s>$($cert.Subject)"
Set-ReceiveConnector "ICESRV06\Client Frontend ICESRV06" -TlsCertificateName $tlscertificatename


###############################################################################
# Check if running in Exchange Management Shell (EMS)
###############################################################################
$isEMS = [bool] (Get-Command -eq Ignore Get-ExCommand -ErrorAction SilentlyContinue)
if ($isEMS)
{ 
    Write-Host "Using EMS"
} else {
    Write-Host "Using normal PS"
}

###############################################################################
# Get mailbox statistics
###############################################################################
$MBXStat = Get-MailboxStatistics -Identity <MailboxIdentity> -ErrorAction SilentlyContinue
#PowerShell Remoting
$MBXStat.TotalItemSize.Value -replace '.*\(| bytes\).*|,' | % {'{0:N2}' -f ($_ / 1mb)}
#EMS
$MBXStat.TotalItemSize.Value.ToMB()