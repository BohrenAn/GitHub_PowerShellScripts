###############################################################################
# Exchange Server commands
# Andres Bohren
###############################################################################

#Certificate On Connector
$cert = Get-ExchangeCertificate -Thumbprint <ThumbPrint>
$tlscertificatename = "<i>$($cert.Issuer)<s>$($cert.Subject)"
Set-ReceiveConnector "ICESRV06\Client Frontend ICESRV06" -TlsCertificateName $tlscertificatename