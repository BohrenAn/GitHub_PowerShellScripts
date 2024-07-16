###############################################################################
# Get-Mailprotection.ps1
# Andres Bohren / www.icewolf.ch / blog.icewolf.ch / info@icewolf.ch
#
# Version 1.0 / 21.02.2015 Initial Version
# Version 1.1 / 08.04.2015 IDN Domains / Crawled Domains / Unique Domains
# Version 1.2 / 13.04.2015 STARTTLS Support
# Version 1.3 / 26.08.2022 Addet BIMI / DANE / MTA-STS / M365 Checks
# Version 1.4 / 03.10.2022 Addet Reverse Lookup of MX Records / CAA Lookup / TLS-RPT Lookup
# Version 1.5 / 13.10.2022 Fixed Lyncdiscover / Added NS Records & Autodiscover / Minor fixes
# Version 1.6 / 03.04.2023 Addet Parameter -SMTPConnect [true/false] and -ReturnObject [false/true] that is now a PSCustomObject
# Version 1.7 / 16.05.2023 Fixed Lyncdiscover CNAME
# Version 1.8 / 30.09.2023 - Andres Bohren
# - Fixed ReturnObject Nameserver
# - Changed MTA-STSAvailable to MTA-STSAvailable and MTA-STSWeb to MTASTSWeb in ReturnObject
# - ReturnObject of MTASTSWeb is now String
# - ReturnObject of TLSRPT is now String
# - ReturnObject of MXIP is now Array
# - ReturnObject of CAA is now Array
# Version 1.9 / 29.10.2023 - Andres Bohren
# - Fixed Error in Nameserver Output
# - Improved SMTP Connect
# - Addet SMTPBanner
# - Addet SMTPCertificateIssuer
# - Fixed Errorhandling in DANE and NS Lookups
# - Better Errorhandling in SMTPConnect
# - Fixed Autodiscover Lookup
# - Fixed Lyncdiscover Lookup
# - General cleanup of Code
# - Added Security.txt https://securitytxt.org/
# - Added -Silent Parameter
# Version 1.10
# - Fixed STARTTLS and STARTTLS Support in Output and ReturnValue
# Version 1.11
# - Fixed Issue when testing SMTP Connectivity
# Version 1.12
# - Fixed Bug in Detection of Multiple SPF Records
# Version 1.13 30.03.2024
# - Fixed Bug in DANESupport when -SMTPConnect was set to $false
# Version 1.14
# - Moved from Resolve-DNS to DNS Over Https DoH (https://dns.google/resolve)
# Backlog / Whishlist
# - External Domain Validation DMARC Authorisation Record
#   - txt domain.tld._report._dmarc.ag.us.dmarcian.com
# - SPF Record Lookup check if max 10 records are used
# - Open Mail Relay Check
# - Parameter for DKIM Selector
###############################################################################

<#PSScriptInfo
.VERSION 1.14
.GUID 3bd03c2d-6269-4df1-b8e5-216a86f817bb
.AUTHOR Andres Bohren Contact: a.bohren@icewolf.ch https://twitter.com/andresbohren
.COMPANYNAME icewolf.ch
.COPYRIGHT Free to copy, inspire, etc...
.TAGS DNSSEC, MX, Reverse Lookup, STARTTLS, SPF, DKIM, DMARC, DANE, MTA-STS, TLSRPT, BIMI, CAA, M365, TenantID, Security.txt
.LICENSEURI
.PROJECTURI https://github.com/BohrenAn/GitHub_PowerShellScripts/tree/main/Mailprotection
.ICONURI
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
Version 1.14
- Moved from Resolve-DNS to DNS Over Https (https://dns.google/resolve)
#>

<#
.SYNOPSIS 
Script written by Andres Bohren https://blog.icewolf.ch / a.bohren@icewolf.ch

This Script checks diffrent DNS Records about a Domain - mostly about Mailsecurity Settings.
It checks for the following Information
- DNS Zone Signed (DNSSEC)
- NS (Nameserver)
- CAA (Certification Authority Authorization)
- MX (MailExchanger)
- MX IP
- MX Reverse Lookup
- Connects to the MX Servers and checks for STARTTLS and shows SMTP Banner and Certificate Information
- SPF (Sender Policy Framework)
- DKIM (DomainKeys Identified Mail)
- DMARC (Domain-based Message Authentication, Reporting and Conformance)
- DANE (DNS-based Authentication of Named Entities)
- BIMI (Brand Indicators for Message Identification)
- MTA-STS (SMTP MTA Strict Transport Security)
- MTA-STS Web (https://mta-sts.domain.tld/.well-known/mta-sts.txt)
- TLSRPT (TLS Reporting)
- Autodiscover (Outlook)
- Lyncdiscover
- Lync/Skype/Teamsfederation
- M365 (Check via Open ID Connect)
- M365 TenantID
- Security.txt https://securitytxt.org/

.DESCRIPTION 
This Script checks diffrent DNS Records about a Domain - mostly about Mailsecurity Settings.
Most of the Querys are simple DNS Querys (NS, MX, SPF, DKIM, DMARC, BIMI, MTA-STS, TLSRPT).
The Script uses also DNS over HTTP for several checks (ZoneSigned, TLSA Record for DANE).
Also some Webrequests are required for MTA-STS, TenantID (OIDC), Security.txt.
And connects via SMTP to check if the Server supports STARTTLS.

.NOTES 
Note that DKIM is hard to query, because the Selector can be literally anything.

.LINK 
Script is published here:
https://github.com/BohrenAn/GitHub_PowerShellScripts/tree/main/Mailprotection

.EXAMPLE 
Get-Mailprotection.ps1 -Domain icewolf.ch
$Result = Get-Mailprotection.ps1 -Domain icewolf.ch -ReturnObject $True
$Result = Get-Mailprotection.ps1 -Domain icewolf.ch -SMTPConnect $False -ReturnObject $True

.PARAMETER Domain 
Mandatory Parameter. You need to specify a Domain as a string Value
domain.tld or subdomain.domain.tld

.PARAMETER SMTPConnect
Optional Parameter. You can specify not to connect with SMTP to the Server. Per Default this Setting is TRUE.
You add the Parameter -SMTPConnect $False

.PARAMETER ReturnObject
Optional Parameter. You can specify if a the Script returns an Object (For Scripting purposes). Per Default this Setting is FALSE.
You can add the Parameter -ReturnObject $True

.PARAMETER Silent
Optional Parameter. You can specify to not get an Output to the Console. Per Default this Setting is FALSE.
You can add the Parameter -Silent $True. 
Can be helpful if you use it with the -ReturnObject $True
#>


PARAM (
	[Parameter(Mandatory=$true)][String]$Domain,
	[Parameter(Mandatory=$false)][bool]$SMTPConnect = $True,
	[Parameter(Mandatory=$false)][bool]$ReturnObject = $false,
	[Parameter(Mandatory=$false)][bool]$Silent = $false
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
		PARAM (
			[Parameter(Mandatory=$true)][String]$SMTPServer
			)

		[bool]$TLSSupport = $false
		$Port = "25"
		#$Sendingdomain = "mail.icewolf.ch"
		$Sendingdomain = "$env:computername.$env:userdnsdomain"
	try {
			If ($Silent -ne $True)
			{
				Write-Host("Connect $SMTPServer $Port") -ForegroundColor Magenta
			}
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
			If ($Silent -ne $True)
			{
				Write-Host($ConnectResponse)
			}
			if(!$ConnectResponse.StartsWith("220")){
				#throw "Error connecting to the SMTP Server"
			} else {
				$SMTPBanner = $ConnectResponse
			}

			#Send "EHLO"
			If ($Silent -ne $True)
			{
				Write-Host(("EHLO " + $Sendingdomain)) -ForegroundColor Magenta
			}
			$streamWriter.WriteLine(("EHLO " + $Sendingdomain));

		} catch {
			If ($Silent -ne $True)
			{
				Write-Host "ERROR $_"
			}
		}

		$response = @()
		Try {
			while($streamReader.EndOfStream -ne $true)
			{
					$ehloResponse = $streamReader.ReadLine();
					If ($Silent -ne $True)
					{
						Write-Host($ehloResponse)
					}
					$response += $ehloResponse
			}
		} catch {

			If ($response -match "STARTTLS")
			{
					$TLSSupport = $true

					#StartTLS found
					If ($Silent -ne $True)
					{
						Write-Host("STARTTLS") -ForegroundColor Magenta
					}

					$streamWriter.WriteLine("STARTTLS");
					$startTLSResponse = $streamReader.ReadLine();
					If ($Silent -ne $True)
					{
						Write-Host($startTLSResponse)
					}

					#Get Certificate
					$ccCol = New-Object System.Security.Cryptography.X509Certificates.X509CertificateCollection
					$sslStream.AuthenticateAsClient($ServerName,$ccCol,[System.Security.Authentication.SslProtocols]::Tls12,$false)
					$Cert = $sslStream.RemoteCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)

					#Show Certificate Details
					If ($Silent -ne $True)
					{
						Write-Host "Certificate Details:" -ForegroundColor Green
						Write-Host "Issuer: $($sslStream.RemoteCertificate.Issuer)"
						Write-Host "Subject: $($sslStream.RemoteCertificate.Subject)"
						Write-Host "ValidFrom: $($sslStream.RemoteCertificate.GetEffectiveDateString())"
						Write-Host "ValidTo: $($sslStream.RemoteCertificate.GetExpirationDateString())"
						Write-Host "SerialNumber: $($sslStream.RemoteCertificate.GetSerialNumberString())"
						Write-Host "Thumbprint: $($sslStream.RemoteCertificate.GetCertHashString())"
					}

					$SMTPCertIssuer = $sslStream.RemoteCertificate.Issuer

					$stream.Dispose()
					$sslStream.Dispose()

			} else {
				If ($Silent -ne $True)
				{
					Write-Host "ERROR: No <STARTTLS> found" -ForegroundColor Yellow
				}
				[bool]$TLSSupport = $false
			}
		}

		$ResultObject = [PSCustomObject]@{}
		$ResultObject | Add-Member -MemberType NoteProperty -Name 'SMTPBanner' -Value $SMTPBanner
		$ResultObject | Add-Member -MemberType NoteProperty -Name 'SMTPCertIssuer' -Value $SMTPCertIssuer
		$ResultObject | Add-Member -MemberType NoteProperty -Name 'TLSSupport' -Value $TLSSupport

		return $ResultObject
		#return $TLSSupport
	}

###############################################################################
# Function Get-MailProtection
###############################################################################
Function Get-MailProtection
{
	[cmdletbinding()]
	PARAM (
	[Parameter(Mandatory=$true)][String]$Domain,
	[Parameter(Mandatory=$false)][Bool]$SMTPConnect
	)

	[bool]$ZoneDNSSigned = $false
	[Array]$Nameserver = @()
	[Array]$MXRecord = @()
	[Array]$MXReverseLookup = @()
	[String]$DANERecord = $Null
	[bool]$MXAvailable = $False
	[int]$MXCount = 0
	$MXReverseLookup = $Null
	[int]$StartTLSCount = 0
	[bool]$SPFAvailable = $False
	[string]$SPFRecord = $Null
	[bool]$DomainKeyAvailable = $False
	[String]$DomainKeySupport = "None"
	[bool]$DMARCAvailable = $False
	[string]$DMARCRecord = $Null
	[int]$DANECount = 0
	[bool]$DANEAvailable = $false
	[string]$DANESupport = "None"
	[bool]$M365 = $False
	[bool]$BIMIAvailable = $False
	[string]$BIMIRecord = $Null
	[bool]$MTASTSAvailable = $false
	[string]$Autodiscover = $Null
	[string]$LyncDiscover = $Null

	## Check if DNS Zone is signed
	If ($Silent -ne $True)
	{
		Write-Host "Check: DNS Zone Signed" -ForegroundColor Green
	}
	$URI = "https://dns.google/resolve?name=$Domain&type=NS"
	$json = Invoke-RestMethod -URI $URI
	If ($json.ad -eq "True")
	{
		$ZoneDNSSigned = $true
	}

	## Nameserver (NS)
	<#
	$Nameserver = $Null
	$NS = Resolve-DnsName -Type NS $Domain -ErrorAction SilentlyContinue
	If ($null -ne $NS)
	{
		[Array]$Nameserver = $NS.NameHost
	}
	#>
	Foreach ($Entry in $json.Answer.data)
	{
		$Nameserver += $Entry.Substring(0,$Entry.Length-1)
	}

	## CAA
	If ($Silent -ne $True)
	{
		Write-Host "Check: CAA" -ForegroundColor Green
	}
	#https://de.wikipedia.org/wiki/DNS_Certification_Authority_Authorization
	#$Domain = "iis.se"
	$CAA = $Null
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=CAA"
	If ($Null -ne $json.Answer.Data)
	{
		[Array]$CAA = $json.Answer.Data # ($json.Answer.Data | Out-String).Trim()
	}

	##Check for MX Record
	If ($Silent -ne $True)
	{
		Write-Host "Check: MX" -ForegroundColor Green
	}
	<#
	$MX = Resolve-DnsName -Name $Domain -Type MX -ErrorAction SilentlyContinue
	[Array]$MXRecord = $MX.NameExchange #($mx.nameExchange | Out-String).Trim()
	If ($NULL -eq $MXRecord -or $MXRecord -eq "" -or $MXRecord -eq $False)
	{
		$MXRecord = $NULL
	}
	#>
	$URI = "https://dns.google/resolve?name=$Domain&type=MX"
	$json = Invoke-RestMethod -URI $URI
	Foreach ($Entry in $json.Answer.data)
	{
		$MXRecordData = $Entry.Substring(0,$Entry.Length-1)
		$MXRecord += $MXRecordData.split(" ")[1]
	}

	Foreach ($MXEntry in $MXRecord)
	{
		#If ($Null -ne $MXEntry.NameExchange)
		If ($Null -ne $MXEntry)
		{
			#MX Found
			$MXAvailable = $true
			$MXCount = $MXCount + 1

			#ReverseLookup
			#$MXIP = Resolve-DnsName $MXEntry.NameExchange -ErrorAction SilentlyContinue | Where-Object {$_.Type -eq "A"}
			$URI = "https://dns.google/resolve?name=$MXEntry&type=A"
			$json = Invoke-RestMethod -URI $URI
			$MXIP = $json.Answer.Data
			
			#Foreach ($IP in $MXIP.IPAddress)
			Foreach ($IP in $MXIP)
			{
				[Array]$MXIPArray += $IP
				#$ReverseLookupName = Resolve-DnsName $IP -ErrorAction SilentlyContinue
				$SplitIP = $IP.split(".")
				$ReverseLookupIP = $SplitIP[3] + "." + $SplitIP[2] + "." + $SplitIP[1] + "." + $SplitIP[0] + ".in-addr.arpa."
				$URI = "https://dns.google/resolve?name=$ReverseLookupIP&type=PTR"
				$json = Invoke-RestMethod -URI $URI
				$ReverseLookupName = $json.Answer.Data
				$ReverseLookupName = $ReverseLookupName.Substring(0,$ReverseLookupName.Length-1)

				If ($Null -ne $ReverseLookupName)
				{
					[Array]$MXReverseLookup += $ReverseLookupName
				}
			}

			#StartTLS
			#Only Connect if Parameter $SMTPConnect is True (default)
			If ($SMTPConnect -eq $True)
			{
				If ($Silent -ne $True)
				{
					Write-Host "Check: SMTPConnect" -ForegroundColor Green
				}
				#$TestConnection = Test-NetConnection $MXEntry.NameExchange -Port 25
				#If ($TestConnection.TcpTestSucceeded -eq $true)
				try {
					$tcpClient = New-Object System.Net.Sockets.TcpClient
					#$portOpened = $tcpClient.ConnectAsync($MXEntry.NameExchange, "25").Wait(1000)
					$portOpened = $tcpClient.ConnectAsync($MXEntry, "25").Wait(1000)
				} catch {
					$PortOpened = $false
				}
				#$PortOpened 

				If ($PortOpened -eq $true)
				{
					If ($Silent -ne $True)
					{
						Write-Host "Check: StartTLS" -ForegroundColor Green
					}
					$StartTLSReturn = Invoke-STARTTLS -SMTPServer $MXEntry
					[Array]$SMTPBannerArray += $StartTLSReturn.SMTPBanner
					[Array]$SMTPCertIssuerArray += $StartTLSReturn.SMTPCertIssuer
				}
			}
			If ($StartTLSReturn.TLSSupport -eq $true)
			{
				$StartTLSCount = $StartTLSCount + 1
			}

			try {

			#DANE
			If ($Silent -ne $True)
			{
				Write-Host "Check: DANE" -ForegroundColor Green
			}
			$TLSAQuery = "_25._tcp.$($MXEntry.NameExchange)"
			#$URL= "https://dns.google/resolve?name=$TLSAQuery&type=TLSA"
			#Write-Host "DEBUG: TLSAQuery: $TLSAQuery" -ForegroundColor magenta
			#Write-Host "DEBUG: URI https://dns.google/resolve?name=$TLSAQuery&type=TLSA" -ForegroundColor magenta

			$json = $Null
			$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$TLSAQuery&type=TLSA"

			} catch {
				If ($Silent -ne $True)
				{
					Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ -ForegroundColor Yellow
					Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription -ForegroundColor Yellow
					Write-Host "Query:" $TLSAQuery -ForegroundColor Yellow
				}
			} 
			If ($null -ne $json.Answer.data)
			{
				#DANE Found
				$TLSA = $json.Answer.data
				#$TLSA
				$DANEAvailable = $true
				$DANECount = $DANECount + 1
				$DANERecord = $DANERecord + $TLSA
			}
			
		}
	}

	#Check if all MX support StartTLS
	If ($Silent -ne $True)
	{
		Write-Host "Check: StartTLS Support" -ForegroundColor Green
	}
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
		If ($SMTPConnect -ne $false)
		{
			If ($StartTLSCount -eq 0)
			{
				#None Mailserver in MX Records support DANE
				$DANESupport = "None"
			}
		}
	}

	## SPF
	If ($Silent -ne $True)
	{
		Write-Host "Check: SPF" -ForegroundColor Green
	}

	#$TXT = Resolve-DnsName -Name $Domain -Type TXT -ErrorAction SilentlyContinue
	#$SPFRecord = $TXT.strings -match "v=spf"
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=TXT" 
	$SPFRecord = $json.Answer.data | Where-Object {$_ -like "V=SPF1*"}
	If ($SPFRecord.Count -eq 0) 
	{
		$SPFRecord = $NULL
	} else {
		#SPF Record Presend
		If ($SPFRecord.Count -eq 1)
		{
			[string]$SPFRecord = ($SPFRecord | Out-String).Replace("'","").Trim()
		} else {
			$SPFRecord = "MULTIPLE SPF RECORDS"
		}
	}

	#Foreach ($TXTEntry in $TXT)
	Foreach ($TXTEntry in $json.Answer.data)
	{
		#If ($TXTEntry.Strings -match "v=spf" -or $TXTEntry.Strings -match "spf2.0")
		If ($TXTEntry -match "v=spf" -or $TXTEntry -match "spf2.0")
		{
			#SPF Found
			$SPFAvailable = $true
		}
	}


	## Check for DomainKey / DKIM
	If ($Silent -ne $True)
	{
		Write-Host "Check: DKIM" -ForegroundColor Green
	}
	$DomainKeyRecord = $Null
	$DomainKeySupport = $False
	<#
	#$Domainkey = Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=TXT" 
	$SPFRecord = $json.Answer.data | Where-Object {$_ -like "V=SPF1*"}
	Foreach ($Key in $DomainKey)
	{
		If ($Null -ne $KEY.Strings)
		{
			#DomainKey Found
			$DomainKeyAvailable = $true
			$DomainKeySupport = $True
			$DomainKeyRecord = $KEY.Strings
		}
	}
	#>

	#Try O365 Selector1 and Selector2
	If ($DomainKeyAvailable -eq $false)
	{
		$dnshost1 = "selector1._domainkey." + $Domain
		$dnshost2 = "selector2._domainkey." + $Domain
		#$DomainkeyS1 = Resolve-DnsName -Name $dnshost1 -Type CNAME -ErrorAction SilentlyContinue
		$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost1&type=CNAME"
		#$DKIMRecord1 = $json.Answer.data | Where-Object {$_ -like "v=DKIM1*"}
		$DKIMRecord1 = $json.Answer.data

		#$DomainkeyS2 = Resolve-DnsName -Name $dnshost2 -Type CNAME -ErrorAction SilentlyContinue
		$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost2&type=CNAME"
		#$DKIMRecord2 = $json.Answer.data | Where-Object {$_ -like "v=DKIM1*"}
		$DKIMRecord2 = $json.Answer.data

		If ($Null -ne $DKIMRecord1 -or $Null -ne $DKIMRecord2)
		{
			$DomainKeySupport = $True
			$DomainKeyAvailable = $True
			[Array]$DomainKeyRecord += $DKIMRecord1.Substring(0,$DKIMRecord1.Length-1)
			[Array]$DomainKeyRecord += $DKIMRecord2.Substring(0,$DKIMRecord2.Length-1)
		}
	}
	<#
	#If DomainKey TXT is not Available check NS
	$dnshost = "_domainkey." + $Domain
	If ($DomainKeyAvailable -eq $false)
	{
		#If DomainKey TXT is not Available check NS
		#$DomainkeyNS = Resolve-DnsName -Name $dnshost -Type NS -ErrorAction SilentlyContinue
		$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=NS"
		$DomainkeyNS = $json.Answer.data

		If ($Null -ne $DomainkeyNS)
		{
			$DomainKeySupport = "maybe"
		}
	}
	#>

	## Check for DMARC
	If ($Silent -ne $True)
	{
		Write-Host "Check: DMARC" -ForegroundColor Green
	}
	
	$dnshost = "_dmarc." + $Domain
	#Write-Host "DNSHOST: " $dnshost
	#$DMARC = Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=TXT"
	$DMARC = $json.Answer.data | Where-Object {$_ -like "V=DMARC1*"}
	Foreach ($DMARCEntry in $DMARC)
	{
		$DMARCRecord = $DMARCEntry.Replace("'","")
		$DMARCAvailable = $true
	}

	## BIMI
	If ($Silent -ne $True)
	{
		Write-Host "Check: BIMI" -ForegroundColor Green
	}
	#default._bimi.example.com in txt
	#"v=BIMI1; l=https://www.example.com/path/to/logo/example.svg; a=https://www.example.com/path/to/vmc/VMC.pem;"
	$dnshost = "default._bimi." + $Domain
	#$BIMI = Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=TXT"
	$BIMI = $json.Answer.data | Where-Object {$_ -like "V=BIMI1*"}
	Foreach ($BIMIEntry in $BIMI)
	{
			#BIMI Found
			$BIMIAvailable = $true
			[String]$BIMIRecord = $BIMIEntry -Join " "
	}

	## MTA STS
	If ($Silent -ne $True)
	{
		Write-Host "Check: MTA-STS" -ForegroundColor Green
	}
	#mta-sts.domain.de/.well-known/mta-sts.txt	
	#https://mta-sts.dmarcian.com/.well-known/mta-sts.txt
	#$Domain = "dmarcian.com"
	#$Domain = "google.com"
	#$Domain = "icewolf.ch"
	$DNSHost = "_mta-sts." + $Domain
	#$MTASTS = Resolve-DnsName -Name $DNSHost -Type TXT -ErrorAction SilentlyContinue
	$MTASTSAvailable = $False
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=TXT"
	$MTASTS = $json.Answer.data | Where-Object {$_ -like "V=STSv1*"}
	Foreach ($MTASTSEntry in $MTASTS)
	{
		#MTA-STS Found
		$MTASTSAvailable = $true
		#Write-Host "MTA STS Found" -ForegroundColor Green

		$URI = "https://mta-sts.$Domain/.well-known/mta-sts.txt"
		try {
			$Response = Invoke-WebRequest -URI $URI -TimeoutSec 1
			$MTASTSTXT = ($response.Content).trim().Replace("`r`n","")
		#$MTASTSTXT
		} catch {
			#If ($Silent -ne $True)
			#{
				Write-Verbose "An exception was caught: $($_.Exception.Message)" #-ForegroundColor Yellow
			#}
		}
	}

	## TLS-RPT
	#_smtp._tls.google.com IN TXT "{v=TLSRPTv1;rua=mailto:sts-reports@google.com}"
	If ($Silent -ne $True)
	{
		Write-Host "Check: TLS-RPT" -ForegroundColor Green
	}
	$TLSRPTQuery = "_smtp._tls.$Domain"
	#$TLSRPT = Resolve-DnsName -Name $TLSRPTQuery -Type TXT -ErrorAction SilentlyContinue
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$TLSRPTQuery&type=TXT"
	$TLSRPT = $json.Answer.data | Where-Object {$_ -like "V=TLSRPTv1*"}
	If ($Null -ne $TLSRPT)
	{
		[String]$TLSRPTRecord = $TLSRPT
	}

	## Autodiscover
	#AutodiscoverV2
	#$URI = "https://autodiscover.icewolf.ch/autodiscover/autodiscover.json/v1.0/info@$domain?Protocol=AutodiscoverV1"
	$Autodiscover = $Null
	$AutodiscoverCNAME = $Null
	$AutodiscoverA = $Null

	If ($Silent -ne $True)
	{
		Write-Host "Check: Autodiscover" -ForegroundColor Green
	}
	#[array]$Autodiscover = Resolve-DnsName -Name autodiscover.$Domain -ErrorAction SilentlyContinue | Where-Object {$_.Type -eq "CNAME" -or $_.Type -eq "A"}
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Autodiscover.$Domain&type=CNAME"
	$AutodiscoverCNAME = $json.Answer.data
	If ($Null -ne $AutodiscoverCNAME)
	{
		$AutodiscoverCNAME = $AutodiscoverCNAME.Substring(0,$AutodiscoverCNAME.Length-1)
		[string]$Autodiscover = $AutodiscoverCNAME
	} else {
		#Autodiscover A
		$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Autodiscover.$Domain&type=A"
		If ($Null -ne $json.Answer.Data)
		{
			$AutodiscoverA = $json.answer.Data[0]
		}
		If ($Null -ne $AutodiscoverA)
		{
			Try {
				#Check if IPv4
				$IP = [system.net.ipaddress]$AutodiscoverA
				$Autodiscover = $AutodiscoverA
			} catch {
				#Then it must be a DNS Name
				$AutodiscoverA = $AutodiscoverA.Substring(0,$AutodiscoverA.Length-1)
				[string]$Autodiscover = $AutodiscoverA
			}
		} else {
			#Autodiscover SRV
			$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=_autodiscover._tcp.$Domain&type=SRV"
			$AutodiscoverSRV = $json.Answer.data
			If ($Null -ne $AutodiscoverSRV)
			{
				$AutodiscoverSRV = $AutodiscoverSRV.Substring(0,$AutodiscoverSRV.Length-1)
				[string]$Autodiscover = $AutodiscoverSRV
			} else {
				$Autodiscover = $Null
			}
		}
	}


	## LyncDiscover
	If ($Silent -ne $True)
	{
		Write-Host "Check: Lyncdiscover" -ForegroundColor Green
	}
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Lyncdiscover.$Domain&type=CNAME"
	$LyncDiscoverCNAME = $json.Answer.data
	If ($Null -ne $LyncDiscoverCNAME)
	{
		$LyncDiscoverCNAME = $LyncDiscoverCNAME.Substring(0,$LyncDiscoverCNAME.Length-1)
		[string]$Lyncdiscover = $LyncDiscoverCNAME
	} else {
		#Lyncdiscover A
		$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Lyncdiscover.$Domain&type=A"
		If ($Null -ne $json.Answer.data)
		{
			$LyncDiscoverA = $json.answer.Data[0]
		}
		
		If ($Null -ne $LyncDiscoverA)
		{
			$LyncDiscoverA = $LyncDiscoverA.Substring(0,$LyncDiscoverA.Length-1)
			[string]$Lyncdiscover = $LyncDiscoverA
		} else {
			$Lyncdiscover = $Null
		}
	}

	## Skype4B / Teams Federation
	If ($Silent -ne $True)
	{
		Write-Host "Check: Skype4B / Teams Federation" -ForegroundColor Green
	}
	#$SRV = Resolve-DnsName _sipfederationtls._tcp.$Domain -Type SRV -ErrorAction SilentlyContinue
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=_sipfederationtls._tcp.$Domain&type=SRV"
	$SkypeFederationSRV = $json.Answer.data
	If ($null -ne $SkypeFederationSRV)
	{
		$SkypeFederationSRV = $SkypeFederationSRV.Split(" ")[3]
		$SkypeFederationSRV = $SkypeFederationSRV.Substring(0,$SkypeFederationSRV.Length-1)
		$SkypeFederation = $SkypeFederationSRV
	} else {
		$SkypeFederation = $Null
	}

	## M365
	If ($Silent -ne $True)
	{
		Write-Host "Check: M365 Tenant (OpenIDConnect)" -ForegroundColor Green
	}
	try {
		#$TenantID = (Invoke-WebRequest -UseBasicParsing https://login.windows.net/$($Domain)/.well-known/openid-configuration|ConvertFrom-Json).token_endpoint.Split('/')[3] 
		$Response = Invoke-WebRequest -UseBasicParsing https://login.windows.net/$($Domain)/.well-known/openid-configuration -TimeoutSec 1
		$TenantID = ($Response | ConvertFrom-Json).token_endpoint.Split('/')[3]
		$M365 = $True 

	} catch {
		#If ($Silent -ne $True)
		#{
			Write-Verbose "An exception was caught: $($_.Exception.Message)" #-ForegroundColor Yellow
		#}
		#$TenantID = "NULL"
		$TenantID = $Null
		$M365 = $False 
	}

	## Check for https://securitytxt.org/
	# Example: https://www.admin.ch/.well-known/security.txt
	If ($Silent -ne $True)
	{
		Write-Host "Check: security.txt" -ForegroundColor Green
	}

	[bool]$SecurityTXTAvailable = $false
	$URI = "https://$Domain/.well-known/security.txt"
	try {
		$Response = Invoke-WebRequest -UseBasicParsing -URI $URI -TimeoutSec 1
		If ($Null -ne $Response)
		{
			[bool]$SecurityTXTAvailable = $true
		}
	} catch {
		#If ($Silent -ne $True)
		#{
			Write-Verbose "An exception was caught: $($_.Exception.Message)" #-ForegroundColor Yellow
		#}
	}

	$URI = "https://$Domain/security.txt"
	try {
		$Response = Invoke-WebRequest -UseBasicParsing -URI $URI -TimeoutSec 1
		If ($Null -ne $Response)
		{
			[bool]$SecurityTXTAvailable = $true
		}
	} catch {
		#If ($Silent -ne $True)
		#{
			Write-Verbose "An exception was caught: $($_.Exception.Message)" #-ForegroundColor Yellow
		#}
	}

	# Convert Arrays to String
	$MXIPString = $MXIPArray -join " "
	If ($Null -ne $Nameserver -or $Nameserver -ne "")
	{
		$NameserverString = $Nameserver -Join " "
	}

	[String]$SMTPBanner = ""
	If ($Null -ne $SMTPBannerArray)
	{
		$SMTPBanner = $SMTPBannerArray -join " "
	}

	[String]$SMTPCertIssuer = ""
	If ($Null -ne $SMTPCertIssuerArray)
	{
		$SMTPCertIssuer = $SMTPCertIssuerArray -join " "
	}

	#Write Output
	If ($Silent -ne $True)
	{
		Write-Host "SUMMARY: $Domain" -ForegroundColor cyan
		Write-Host "Nameserver:" $NameserverString -ForegroundColor cyan
		Write-Host "Zone DNS Signed: $ZoneDNSSigned" -ForegroundColor cyan
		Write-Host "Certification Authority Authorization (CAA): $CAA" -ForegroundColor cyan
		Write-Host "MXCount: $MXCount" -ForegroundColor cyan
		Write-Host "MXRecord: $MXRecord" -ForegroundColor cyan
		Write-Host "MXIP: $MXIPString" -ForegroundColor cyan
		Write-Host "MXReverseLookup: $MXReverseLookup" -ForegroundColor cyan
		Write-Host "STARTTLS: $StartTLSCount" -ForegroundColor cyan
		Write-Host "STARTTLS Support: $StartTLSSupport" -ForegroundColor cyan
		Write-Host "SMTPBanner: $SMTPBanner" -ForegroundColor cyan
		Write-Host "SMTPCertIssuer: $SMTPCertIssuer" -ForegroundColor cyan
		Write-Host "SPF: $SPFAvailable" -ForegroundColor cyan
		Write-Host "SPFRecord: $SPFRecord" -ForegroundColor cyan
		Write-Host "DKIM: $DomainKeyAvailable" -ForegroundColor cyan
		Write-Host "DKIM Support: $DomainKeySupport" -ForegroundColor cyan
		Write-Host "DKIM Record: $DomainKeyRecord" -ForegroundColor cyan
		Write-Host "DMARC: $DMARCAvailable " -ForegroundColor cyan
		Write-Host "DMARCRecord: $DMARCRecord" -ForegroundColor cyan
		Write-Host "DANECount: $DANECount" -ForegroundColor cyan
		Write-Host "DANESupport: $DANESupport" -ForegroundColor cyan
		Write-Host "DANERecord: $DANERecord" -ForegroundColor cyan
		Write-Host "BIMI: $BIMIAvailable" -ForegroundColor cyan
		Write-Host "BIMI Record: $BIMIRecord" -ForegroundColor cyan
		Write-Host "MTA-STS: $MTASTSAvailable" -ForegroundColor cyan
		Write-Host "MTA-STS-Web: $MTASTSTXT" -ForegroundColor cyan
		Write-Host "TLS-RPT: $TLSRPTRecord" -ForegroundColor cyan
		Write-Host "Autodiscover: $Autodiscover" -ForegroundColor cyan
		Write-Host "Lyncdiscover: $Lyncdiscover" -ForegroundColor cyan
		Write-Host "SkypeFederation: $SkypeFederation" -ForegroundColor cyan
		Write-Host "M365: $M365" -ForegroundColor cyan
		Write-Host "TenantID: $TenantID" -ForegroundColor cyan
		Write-Host "SecurityTXT: $SecurityTXTAvailable" -ForegroundColor cyan
	}

	#Better ResponseObject
	$ResultObject = [PSCustomObject]@{}
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'Domain' -Value $Domain
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'NameServer' -Value $Nameserver
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'ZoneDNSSigned' -Value $ZoneDNSSigned
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'CAA' -Value $CAA
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'MXCount' -Value $MXCount
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'MXRecord' -Value $MXRecord
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'MXIP' -Value $MXIPArray
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'MXReverseLookup' -Value $MXReverseLookup
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'StartTLSCount' -Value $StartTLSCount
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'StartTLSSupport' -Value $StartTLSSupport
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'SMTPBanner' -Value $SMTPBannerArray
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'SMTPCertIssuer' -Value $SMTPCertIssuerArray
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'SPFAvailable' -Value $SPFAvailable
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'SPFRecord' -Value $SPFRecord
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DomainKeyAvailable' -Value $DomainKeyAvailable
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DomainKeySupport' -Value $DomainKeySupport
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DomainKeyRecord' -Value $DomainKeyRecord
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DMARCAvailable' -Value $DMARCAvailable
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DMARCRecord' -Value $DMARCRecord
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DANECount' -Value $DANECount
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DANESupport' -Value $DANESupport
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'DANERecord' -Value $DANERecord
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'BIMIAvailable' -Value $BIMIAvailable
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'BIMIRecord' -Value $BIMIRecord
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'MTASTSAvailable' -Value $MTASTSAvailable
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'MTASTSWeb' -Value $MTASTSTXT
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'TLSRPT' -Value $TLSRPTRecord
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'Autodiscover' -Value $Autodiscover
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'LyncDiscover' -Value $Lyncdiscover
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'SkypeFederation' -Value $SkypeFederation
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'M365' -Value $M365
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'TenantID' -Value $TenantID
	$ResultObject | Add-Member -MemberType NoteProperty -Name 'SecurityTXT' -Value $SecurityTXTAvailable

	return $ResultObject
}

###############################################################################
# Main Script
###############################################################################
$Result = Get-MailProtection -Domain $Domain -SMTPConnect $SMTPConnect
If ($ReturnObject -eq $true)
{
	$Result
}
