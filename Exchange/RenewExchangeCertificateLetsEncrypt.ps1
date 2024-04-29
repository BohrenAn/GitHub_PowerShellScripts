###############################################################################
# Submit-Renewal To Let's Ecnrypt
# 2023.10.20 - Andres Bohren - Initial Script
###############################################################################
Try {
	Import-Module Posh-ACME
	Submit-Renewal mail.icewolf.ch -NoSkipManualDns -Force
	$Cert = Get-PACertificate

	#Import PFX to LocalMachine Certificate Store
	Import-PfxCertificate -FilePath $Cert.PfxFile -CertStoreLocation Cert:\LocalMachine\My -Password $Cert.PfxPass -Exportable

	#Connect Exchange
	$ExSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://icesrv06.corp.icewolf.ch/PowerShell/ -Authentication Kerberos
	Import-PSSession -Session $ExSession -DisableNameChecking | Out-Null

	#Enable-ExchangeCertificate
	Enable-ExchangeCertificate -Thumbprint $Cert.Thumbprint -Services IIS,SMTP -Force

	#Remove the Certificate from O365 Send Connector
	Set-SendConnector -Identity "Outbound to Office 365 - bf13fea0-cf38-46f6-bab7-f8553f07f3dc" -TlsCertificateName $Null

	#Remove Old Certificate
	$CertArray = Get-ChildItem cert:\localMachine\my | where {$_.subject -eq "CN=mail.icewolf.ch"}
	$CertArray = $CertArray | Sort-Object NotAfter
	$Thumbprint = $CertArray[0].Thumbprint
	Remove-ExchangeCertificate -Thumbprint $Thumbprint -Confirm:$false

	#Set Certificate for O365 Send Connector
	$ExCert = Get-ExchangeCertificate -Thumbprint $Cert.Thumbprint
	$tlscertificatename = "<i>$($ExCert.Issuer)<s>$($ExCert.Subject)"
	Set-SendConnector -Identity "Outbound to Office 365 - bf13fea0-cf38-46f6-bab7-f8553f07f3dc" -TlsCertificateName $tlscertificatename

	#Remove PSSession
	Remove-PSSession $ExSession

	#Send Admin Mail
	$From = "postmaster@icewolf.ch"
	$To = "a.bohren@icewolf.ch"
	$Subject = "Successfully change Exchange Let's Encrypt Certificate"
	$Body = "Sucessfuly changed Exchange Certificate"
	$SMTPServer = "172.21.175.61"
	Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SMTPServer $SMTPServer

} catch {

	#Send Admin Mail
	$From = "postmaster@icewolf.ch"
	$To = "a.bohren@icewolf.ch"
	$Subject = "Error change Exchange Let's Encrypt Certificate"
	$Body = "Error occured while trying to change Exchange Certificate"
	$SMTPServer = "172.21.175.61"
	Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SMTPServer $SMTPServer

}


