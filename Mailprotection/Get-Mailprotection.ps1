###############################################################################
# Get-Mailprotection.ps1
# Version 1.0 / 21.02.2015 Initial Version
# Version 1.1 / 08.04.2015 IDN Domains / Crawled Domains / Unique Domains
# Version 1.2 / 13.04.2015 STARTTLS Support
# Version 1.3 / 26.08.2022 Addet BIMI / DANE / MTA-STS / M365 Checks
# Version 1.4 / 03.10.2022 Addet Reverse Lookup of MX Records / CAA Lookup / TLS-RPT Lookup
# Version 1.5 / 13.10.2022 Fixed Lyncdiscover 
# Andres Bohren / www.icewolf.ch / blog.icewolf.ch / info@icewolf.ch
# Backlog / Whishlist
# - SPF Record Lookup check if max 10 records are used
# - Open Mail Relay Check
###############################################################################

<#PSScriptInfo
.VERSION 1.4
.GUID 3bd03c2d-6269-4df1-b8e5-216a86f817bb
.AUTHOR Andres Bohren Contact: a.bohren@icewolf.ch https://twitter.com/andresbohren
.COMPANYNAME icewolf.ch
.COPYRIGHT Free to copy, inspire, etc...
.TAGS MX, Reverse Lookup, STARTTLS, SPF, DKIM, DMARC, DANE, MTA-STS, TLS-RPT, CAA, M365 TenantID
.LICENSEURI
.PROJECTURI https://github.com/BohrenAn/GitHub_PowerShellScripts/tree/main/Mailprotection
.ICONURI
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES It's still an early Version and might contain Errors.
.PRIVATEDATA

#>

<#
.SYNOPSIS 
	Script written by Andres Bohren https://blog.icewolf.ch / a.bohren@icewolf.ch

	This Script checks diffrent DNS Records about a Domain - mostly about Mailsecurity Settings.
	It checks for the following Information
	- DNS Zone Signed (DNSSEC)
	- CAA (Certification Authority Authorization)
	- MX (MailExchanger)
	- MX IP
	- MX Reverse Lookup
	- Connects to the MX Servers and checks for STARTTLS and shows Certificate Information
	- SPF (Sender Policy Framework)
	- DKIM (DomainKeys Identified Mail)
	- DMARC (Domain-based Message Authentication, Reporting and Conformance)
	- DANE (DNS-based Authentication of Named Entities)
	- BIMI (Brand Indicators for Message Identification)
	- MTA-STS (SMTP MTA Strict Transport Security)
	- MTA-STS Web (https://mta-sts.domain.tld/.well-known/mta-sts.txt)
	- TLS-RPT (TLS Reporting)
	- Lyncdiscover
	- Lync/Skype/Teamsfederation
	- M365 (Check via Open ID Connect)
	- M365 TenantID
.DESCRIPTION 
	Most of the Querys are simple DNS Querys.
	The Script uses also DNS over HTTP for several checks (ZoneSigned, TLSA Record for DANE).
	Also some WebQuerys are required for MTA-STS / TenantID (OIDC).
.NOTES 
	Please note, the Script is at an early stage and may still contain several errors.

	Note that DKIM is hard to query, because the Selector can be literally anything.
.LINK 
	Script is published here:
	https://github.com/BohrenAn/GitHub_PowerShellScripts/blob/main/ExchangeOnline/Get-Mailprotection.ps1
.EXAMPLE 
	.\Get-Mailprotection.ps1 -Domain icewolf.ch
	$Result = .\Get-Mailprotection.ps1 -Domain icewolf.ch

.PARAMETER Domain 
   You need to specify a Domain as a string Value
   domain.tld or subdomain.domain.tld
#>


PARAM (
	[Parameter(Mandatory=$true)][String]$Domain
	)

	###############################################################################
	# Function Invoke-STARTTLS
	###############################################################################
	# Connect to SMTP Server, check for STARTTLS and then get the Certificate
	# Based on Code from Glen Scales 
	#	  https://github.com/gscales/Powershell-Scripts/blob/master/TLS-SMTPMod.ps1
	# 29.06.2021 V1.0 Andres Bohren - Initial Version
	# 02.08.2022 V1.1 Thomas Nolte - Add optonal ignoring of certifcation errors
	# 01.10.2022 V1.2 Andres Bohren - Fixed an error when connection was not sucessful
	###############################################################################
	Function Invoke-STARTTLS
	{
		PARAM ($SMTPServer)

		[bool]$TLSSupport = $false
		$Port = "25"
		#$Sendingdomain = "mail.icewolf.ch"
		$Sendingdomain = "$env:computername.$env:userdnsdomain"
	try {
			Write-Host("Connect $SMTPServer $Port") -ForegroundColor Magenta
			$socket = new-object System.Net.Sockets.TcpClient($SMTPServer, $Port)
			$stream = $socket.GetStream()
			$streamWriter = new-object System.IO.StreamWriter($stream)
			$streamReader = new-object System.IO.StreamReader($stream)
			$stream.ReadTimeout = 500
			$stream.WriteTimeout = 500  
			$streamWriter.AutoFlush = $true

			$Callback = {param($sender,$cert,$chain,$errors) return $true}
			$sslStream = New-Object System.Net.Security.SslStream($stream, $false, $Callback)

			$sslStream.ReadTimeout = 500
			$sslStream.WriteTimeout = 500	   
			$ConnectResponse = $streamReader.ReadLine();
			Write-Host($ConnectResponse)
			if(!$ConnectResponse.StartsWith("220")){
				#throw "Error connecting to the SMTP Server"
			}

			#Send "EHLO"
			Write-Host(("EHLO " + $Sendingdomain)) -ForegroundColor Magenta
			$streamWriter.WriteLine(("EHLO " + $Sendingdomain));

		} catch {
			Write-Host "ERROR $_"
		}

		$response = @()
		Try {
			while($streamReader.EndOfStream -ne $true)
			{
					$ehloResponse = $streamReader.ReadLine();
					Write-Host($ehloResponse)
					$response += $ehloResponse
			}
		} catch {

			If ($response -match "STARTTLS")
			{

					$TLSSupport = $true

					#StartTLS found
					Write-Host("STARTTLS") -ForegroundColor Magenta	

					$streamWriter.WriteLine("STARTTLS");
					$startTLSResponse = $streamReader.ReadLine();
					Write-Host($startTLSResponse)

					#Get Certificate
					$ccCol = New-Object System.Security.Cryptography.X509Certificates.X509CertificateCollection
					$sslStream.AuthenticateAsClient($ServerName,$ccCol,[System.Security.Authentication.SslProtocols]::Tls12,$false)	
					$Cert = $sslStream.RemoteCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
					#$KeyUsages = $cert.Extensions.keyUsages | Out-String
					#$Cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
					#$cert2 = $sslStream.RemoteCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
					#$PublicKeySize = $cert2.PublicKey.Key.KeySize | Out-String
					#$PublicKeyAlgorithm = $cert2.PublicKey.Key.KeyExchangeAlgorithm | Out-String

					#Show Certificate Details
					Write-Host "Certificate Details:" -ForegroundColor Green
					Write-Host "Issuer: $($sslStream.RemoteCertificate.Issuer)"
					Write-Host "Subject: $($sslStream.RemoteCertificate.Subject)"
					Write-Host "ValidFrom: $($sslStream.RemoteCertificate.GetEffectiveDateString())"
					Write-Host "ValidTo: $($sslStream.RemoteCertificate.GetExpirationDateString())"
					Write-Host "SerialNumber: $($sslStream.RemoteCertificate.GetSerialNumberString())"
					Write-Host "Thumbprint: $($sslStream.RemoteCertificate.GetCertHashString())"
					#Write-Host "KeyUsage: $KeyUsages"
					#Write-Host "PublicKeySize: $PublicKeySize"
					#Write-Host "PublicKeyAlgorithm: $PublicKeyAlgorithm"

					$stream.Dispose()
					$sslStream.Dispose()

			} else {
					Write-Host "ERROR: No <STARTTLS> found" -ForegroundColor Red
					[bool]$TLSSupport = $false
			}

		}
		return $TLSSupport
	}

###############################################################################
# Function Get-MailProtection
###############################################################################
Function Get-MailProtection
{
PARAM (
	[Parameter(Mandatory=$true)][String]$Domain
	)

	[bool]$ZoneDNSSigned = $false
	[string]$CAA = ""
	[bool]$MXAvailable = $False
	[int]$MXCount = 0
	[string]$MXRecord = ""
	[string]$MXReverseLookup = ""
	[int]$StartTLSCount = 0
	[bool]$SPFAvailable = $False
	[string]$SPFRecord = ""
	[bool]$DomainKeyAvailable = $False
	[String]$DomainKeySupport = ""
	[string]$DomainKeyRecord = ""
	[bool]$DMARCAvailable = $False
	[string]$DMARCRecord = ""
	[int]$DANECount = 0
	[bool]$DANEAvailable = $false
	[string]$DANESupport = 0
	[string]$DANERecord = ""
	[bool]$M365 = $False
	[bool]$BIMIAvailable = $False
	[string]$BIMIRecord = ""
	[bool]$MTASTSAvailable = $false
	#[Array]$Result = @()

	##Check if DNS Zone is signed
	Write-Host "Check: DNS Zone Signed" -foregroundcolor Green
	$URI = "https://dns.google/resolve?name=$Domain&type=NS"	
	$json = Invoke-RestMethod -URI $URI
	If ($json.ad -eq "True")
	{
		#Write-Host "DNS Zone signed" -foregroundcolor Green
		$ZoneDNSSigned = $true
	}

	#CAA
	#https://de.wikipedia.org/wiki/DNS_Certification_Authority_Authorization
	#$Domain = "iis.se"
	
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=CAA"
	If ($Null -ne $json)
	{
		#$json.Answer
		#$json.Answer.Data
		$CAA = ($json.Answer.Data | Out-String).Trim()
	}
	

	##Check for MX Record
	Write-Host "Check: MX Record" -foregroundcolor Green
	$MX = Resolve-DnsName -Name $Domain -Type MX -ErrorAction SilentlyContinue
	$MXRecord = ($mx.nameExchange | Out-String).Trim()
	If ($NULL -eq $MXRecord -or $MXRecord -eq "" -or $MXRecord -eq $False)
	{
		$MXRecord = $NULL
	}

	Foreach ($MXEntry in $MX)
	{
		If ($Null -ne $MXEntry.NameExchange)
		{
			#MX Found
			$MXAvailable = $true
			$MXCount = $MXCount + 1
			#Write-Host "MX Found: " $MXEntry.NameExchange -foregroundcolor Green

			#ReverseLookup
			$MXIP = Resolve-DnsName $MXEntry.NameExchange -ErrorAction SilentlyContinue | Where-Object {$_.Type -eq "A"}
			Write-Host "MXIP $($MXIP.IPAddress)" -foregroundcolor cyan			
			Foreach ($IP in $MXIP.IPAddress)
			{
				$MXIPstr = $IP + " " + $MXIPstr
				#Write-Host "DEBUG: IP $IP"
				$ReverseLookupName = Resolve-DnsName $IP -ErrorAction SilentlyContinue
				#Write-Host "DEBUG: ReverseLookupName $($ReverseLookupName | Out-String)"
				If ($Null -ne $ReverseLookupName)
				{
					Write-Host "MX ReverseLookup $($ReverseLookupName.NameHost)" -foregroundcolor cyan
					$MXReverseLookup = $MXReverseLookup + " " + $ReverseLookupName.NameHost
				}

			}

			#StartTLS
			[bool]$StartTLS = $false
			
			$StartTLS = Invoke-STARTTLS -SMTPServer $MXEntry.NameExchange
			#Write-Host "StartTLS: " $StartTLS
			If ($StartTLS -eq $true)
			{
				$StartTLSCount = $StartTLSCount + 1
			}

			#DANE
			Write-Host "Check: DANE" -foregroundcolor Green
			$TLSAQuery = "_25._tcp.$($MXEntry.NameExchange)"
			#$URL= "https://dns.google/resolve?name=$TLSAQuery&type=TLSA"
			#Write-Host "DEBUG: TLSAQuery: $TLSAQuery" -foregroundcolor magenta
			#Write-Host "DEBUG: URI https://dns.google/resolve?name=$TLSAQuery&type=TLSA" -foregroundcolor magenta

			$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$TLSAQuery&type=TLSA"
			If ($null -ne $json.Answer.data)
			{
				#DANE Found
				$TLSA = $json.Answer.data
				#$TLSA
				$DANEAvailable = $true
				$DANECount = $DANECount + 1
				$DaneRecord = $DaneRecord + $TLSA
			}
			
		}
	}
	#Check if all MX support StartTLS
	Write-Host "Check: StartTLS Support" -foregroundcolor Green
	If ($MXCount -gt 0)
	{
		If ($MXCount -eq $StartTLSCount)
		{
			#All Mailserver in MX Records support STARTTLS
			$StartTLSSupport = "All"
		}
		If ($MXCount -gt $StartTLSCount)
		{
			#Some Mailserver in MX Records support STARTTLS
			$StartTLSSupport = "Some"
		}
		If ($StartTLSCount -eq 0)
		{
			#None Mailserver in MX Records support STARTTLS
			$StartTLSSupport = "None"
		}
	}

	#Check if all MX support DANE
	If ($MXCount -gt 0)
	{
		If ($MXCount -eq $DANECount)
		{
			#All Mailserver in MX Records support DANE
			$DANESupport = "All"
		}
		If ($MXCount -gt $DANECount)
		{
			#Some Mailserver in MX Records support DANE
			If ($DANECount -gt 0)
			{
				$DANESupport = "Some"
			} else {
				$DANESupport = "None"
			}
		}
		If ($StartTLSCount -eq 0)
		{
			#None Mailserver in MX Records support DANE
			$DANESupport = "None"
		}
	}
	#Write-Host "DANE Support: " $DANESupport

	##SPF
	Write-Host "Check: SPF" -foregroundcolor Green
	$SPFRecord = "NULL"
	$TXT = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction SilentlyContinue
	$SPFRecord = $TXT.strings -match "v=spf"
	If ($SPFRecord -eq $false -or $NULL -eq $SPFRecord) 
	{
		$SPFRecord = $NULL
	}

	Foreach ($TXTEntry in $TXT)
	{
		If ($TXTEntry.Strings -match "v=spf" -or $TXTEntry.Strings-match "spf2.0")
		{
			#SPF Found
			$SPFAvailable = $true
			#Write-Host "SPF Found" -foregroundcolor Green
		}
	}

	##Check for DomainKey / DKIM
	Write-Host "Check: DKIM" -foregroundcolor Green
	$DomainKeySupport = "no"
	$DomainKeyRecord = ""
	$dnshost = "_domainkey." + $Domain
	$Domainkey = Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
	Foreach ($Key in $DomainKey)
	{
		If ($Null -ne $KEY.Strings)
		{
			#DomainKey Found
			$DomainKeyAvailable = $true
			$DomainKeySupport = "yes"
			$DomainKeyRecord = $KEY.Strings
			#Write-Host "DomainKey Found" -foregroundcolor Green
		}
	}
	#Try O365 Selector1 and Selector2
	If ($DomainKeyAvailable -eq $false)
	{
		$dnshost1 = "selector1._domainkey." + $Domain
		$dnshost2 = "selector2._domainkey." + $Domain
		$DomainkeyS1 = Resolve-DnsName -Name $dnshost1 -Type CNAME -ErrorAction SilentlyContinue
		$DomainkeyS2 = Resolve-DnsName -Name $dnshost2 -Type CNAME -ErrorAction SilentlyContinue
		If ($Null -ne $DomainkeyS1.NameHost -or $Null -ne $DomainkeyS2.NameHost)
		{
			$DomainKeySupport = "yes"
			$DomainKeyAvailable = $true
			$DomainKeyRecord = $DomainkeyS1.NameHost
			$DomainKeyRecord = $DomainKeyRecord + " " + $DomainkeyS2.NameHost
			#Write-Host "DomainKey <SELECTOR1/2> Found" -foregroundcolor Green
		}
	}
	 #If DomainKey TXT is not Available check NS
	If ($DomainKeyAvailable -eq $false)
	{
		#If DomainKey TXT is not Available check NS
		$DomainkeyNS = Resolve-DnsName -Name $dnshost -Type NS -ErrorAction SilentlyContinue
		If ($Null -ne $DomainkeyNS)
		{
			$DomainKeySupport = "maybe"
			#Write-Host "DomainKey Maybe" -foregroundcolor Green
		}
}

	##Check for DMARC
	Write-Host "Check: DMARC" -foregroundcolor Green
	$DMARCRecord = "NULL" 
	$dnshost = "_dmarc." + $Domain
	#Write-Host "DNSHOST: " $dnshost
	$DMARC = Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
	Foreach ($DMARCEntry in $DMARC)
	{
		If ($DMARCEntry.Strings -match "v=DMARC1")
		{
			#DMARC Found
			$DMARCRecord = $DMARCEntry.Strings
			$DMARCAvailable = $true
			#Write-Host "DMARC Found" -foregroundcolor Green
		}
	}

	##BIMI
	Write-Host "Check: BIMI" -foregroundcolor Green
	$BIMIRecord = ""
	#default._bimi.example.com in txt
	#"v=BIMI1; l=https://www.example.com/path/to/logo/example.svg; a=https://www.example.com/path/to/vmc/VMC.pem;"
	$dnshost = "default._bimi." + $Domain
	$BIMI = Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
	Foreach ($BIMIEntry in $BIMI)
	{
		If ($BIMIEntry.Strings -match "v=BIMI1;")
		{
			#BIMI Found
			$BIMIAvailable = $true
			$BIMIRecord = $BIMIEntry.Strings
			#Write-Host "BIMI Found" -foregroundcolor Green
		}
	}

	#MTA STS
	Write-Host "Check: MTA-STS" -foregroundcolor Green
	#sts.domain.de/.well-known/mta-sts.txt	
	#https://mta-sts.dmarcian.com/.well-known/mta-sts.txt
	#$Domain = "dmarcian.com"
	#$Domain = "google.com"
	#$Domain = "icewolf.ch"
	$dnshost = "_mta-sts." + $Domain
	#Write-Host "DEBUG: MTA-STS: $dnshost" -ForegroundColor Magenta
	$MTASTS = Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
	Foreach ($MTASTSEntry in $MTASTS)
	{
		If ($MTASTSEntry.Strings -match "v=STSv1")
		{
			#DMARC Found
			$MTASTSAvailable = $true
			Write-Host "MTA STS Found" -foregroundcolor Green

			$URI = "https://mta-sts.$Domain/.well-known/mta-sts.txt"
			Write-Host "DEBUG: MTA-STS URI: $URI" -ForegroundColor Magenta
			try {
				$Response = Invoke-WebRequest -URI $URI
				$MTASTSTXT = ($response.Content).trim()
			#$MTASTSTXT
			} catch {
				Write-Host "An exception was caught: $($_.Exception.Message)" -foregroundColor Red
			}
		}
	}

	##TLS-RPT
	#_smtp._tls.google.com IN TXT "{v=TLSRPTv1;rua=mailto:sts-reports@google.com}"
	$TLSRPTQuery = "_smtp._tls.$Domain"
	$TLSRPT = Resolve-DnsName -Name $TLSRPTQuery -Type TXT -ErrorAction SilentlyContinue
	If ($Null -ne $TLSRPT)
	{
		$TLSRPTRecord = $TLSRPT.Strings
	}

	##LyncDiscover
	$Lyncdiscover = Resolve-DnsName lyncdiscover.$Domain -Type A -ErrorAction SilentlyContinue
	$LyncdiscoverCNAME = $Lyncdiscover | Where-Object {$_.Type -eq "CNAME"}
	If ($NULL -ne $LyncdiscoverCNAME)
	{
		$Lyncdiscover = $Lyncdiscover.NameHost
	} else {
		$LyncdiscoverA = $Lyncdiscover | Where-Object {$_.Type -eq "A"}
		If ($NULL -ne $LyncDiscoverA)
		{
			$Lyncdiscover = $Lyncdiscover.Name
		}
	}
	If ($Lyncdiscover -eq "" -or $Null -eq $Lyncdiscover)
	{
		$Lyncdiscover = "NULL"
	}

	##Skype4B / Teams Federation	
	$SRV = Resolve-DnsName _sipfederationtls._tcp.$Domain -Type SRV -ErrorAction SilentlyContinue
	$SkypeFederation = ($SRV.NameTarget | Out-String).Trim()
	If ($SkypeFederation -eq "" -or $Null -eq $SkypeFederation)
	{
		$SkypeFederation = "NULL"
	}

	##M365
	try {
		#$TenantID = (Invoke-WebRequest -UseBasicParsing https://login.windows.net/$($Domain)/.well-known/openid-configuration|ConvertFrom-Json).token_endpoint.Split('/')[3] 
		$Response = Invoke-WebRequest -UseBasicParsing https://login.windows.net/$($Domain)/.well-known/openid-configuration
		$TenantID = ($Response | ConvertFrom-Json).token_endpoint.Split('/')[3]
		$M365 = $True 

	} catch {
		Write-Host "An exception was caught: $($_.Exception.Message)" -foregroundColor Red
		#$_.Exception.Response 
		$TenantID = "NULL"
		$M365 = $False 
	}

	If ($TenantID -eq "")
	{
		$TenantID = "NULL"
	}

	Write-Host "SUMMARY: $Domain" -foregroundcolor cyan
	Write-Host "Zone DNS Signed: $ZoneDNSSigned" -foregroundcolor cyan
	Write-Host "Certification Authority Authorization (CAA): $CAA" -foregroundcolor cyan
	Write-Host "MXCount: $MXCount" -foregroundcolor cyan
	Write-Host "MXRecord: $MXRecord" -foregroundcolor cyan
	Write-Host "MXIP: $MXIPstr" -foregroundcolor cyan
	Write-Host "MXReverseLookup: $MXReverseLookup" -foregroundcolor cyan
	Write-Host "STARTTLS: $StartTLSCount" -foregroundcolor cyan
	Write-Host "STARTTLS Support: $StartTLSSupport" -foregroundcolor cyan
	Write-Host "SPF: $SPFAvailable" -foregroundcolor cyan
	Write-Host "SPFRecord: $SPFRecord" -foregroundcolor cyan
	Write-Host "DKIM: $DomainKeyAvailable" -foregroundcolor cyan
	Write-Host "DKIM Support: $DomainKeySupport" -foregroundcolor cyan
	Write-Host "DKIM Record: $DomainKeyRecord" -foregroundcolor cyan
	Write-Host "DMARC: $DMARCAvailable " -foregroundcolor cyan
	Write-Host "DMARCRecord: $DMARCRecord" -foregroundcolor cyan
	Write-Host "DANECount: $DANECount" -foregroundcolor cyan
	Write-Host "DANESupport: $DANESupport" -foregroundcolor cyan
	Write-Host "DANERecord: $DANERecord" -foregroundcolor cyan
	Write-Host "BIMI: $BIMIAvailable" -foregroundcolor cyan
	Write-Host "BIMI Record: $BIMIRecord" -foregroundcolor cyan
	Write-Host "MTA-STS: $MTASTSAvailable" -foregroundcolor cyan
	Write-Host "MTA-STS-Web: $MTASTSTXT" -foregroundcolor cyan
	Write-Host "TLS-RPT: $TLSRPTRecord" -foregroundcolor cyan
	Write-Host "Lyncdiscover: $Lyncdiscover" -foregroundcolor cyan
	Write-Host "SkypeFederation: $SkypeFederation" -foregroundcolor cyan
	Write-Host "M365: $M365" -foregroundcolor cyan
	Write-Host "TenantID: $TenantID" -foregroundcolor cyan

	#$Result = $MXAvailable, $SPFAvailable, $DomainKeyAvailable,$DMARCAvailable	
	#$Result = $Domain, $ZoneDNSSigned, $CAA, $MXCount, $MXRecord, $MXReverseLookup, $StartTLSCount, $StartTLSSupport, $DANECount, $SPFAvailable, $SPFRecord, $DomainKeyAvailable, $DomainKeySupport, $DomainKeyRecord, $DMARCAvailable, $DMARCRecord, $DANECount, $DANESupport, $DANERecord, $BIMIAvailable, $BIMIRecord, $MTASTSAvailable, $MTASTSTXT, $TLSRPTRecord, $Lyncdiscover, $SkypeFederation, $M365, $TenantId
	#$Result = $Domain, $ZoneDNSSigned, $CAA, $MXCount, $MXRecord, $MXReverseLookup, $StartTLSCount, $StartTLSSupport, $SPFAvailable, $SPFRecord, $DomainKeyAvailable, $DomainKeySupport, $DomainKeyRecord, $DMARCAvailable, $DMARCRecord, $DANECount, $DANESupport, $DANERecord, $BIMIAvailable, $BIMIRecord, $MTASTSAvailable, $MTASTSTXT, $TLSRPTRecord, $Lyncdiscover, $SkypeFederation, $M365, $TenantId
	$Result = @{}
	$Result.Add("Domain", $Domain)
	$Result.Add("ZoneDNSSigned", $ZoneDNSSigned)
	$Result.Add("CAA", $CAA)
	$Result.Add("MXCount", $MXCount)
	$Result.Add("MXRecord", $MXRecord)
	$Result.Add("MXIP", $MXIPstr)
	$Result.Add("MXReverseLookup", $MXReverseLookup)
	$Result.Add("StartTLSCount", $StartTLSCount)
	$Result.Add("StartTLSSupport", $StartTLSSupport)
	$Result.Add("SPFAvailable", $SPFAvailable)
	$Result.Add("SPFRecord", $SPFRecord)
	$Result.Add("DomainKeyAvailable", $DomainKeyAvailable)
	$Result.Add("DomainKeySupport", $DomainKeySupport)
	$Result.Add("DomainKeyRecord", $DomainKeyRecord)
	$Result.Add("DMARCAvailable", $DMARCAvailable)
	$Result.Add("DMARCRecord", $DMARCRecord)	
	$Result.Add("DANECount",$DANECount)
	$Result.Add("DANESupport", $DANESupport)
	$Result.Add("BIMIAvailable", $BIMIAvailable)
	$Result.Add("BIMIRecord", $BIMIRecord)
	$Result.Add("MTA-STS", $MTASTSAvailable)
	$Result.Add("MTS-STS-Web", $MTASTSTXT)
	$Result.Add("TLS-RPT", $TLSRPTRecord)
	$Result.Add("Lyncdiscover", $Lyncdiscover)
	$Result.Add("SkypeFederation", $SkypeFederation)
	$Result.Add("M365", $M365)
	$Result.Add("TenantId", $TenantID)

	return $Result
}

###############################################################################
# Main Script
###############################################################################
$Result = Get-MailProtection -Domain $Domain
$Result