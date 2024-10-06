# Get-Mailprotection

I am working as a Cloud Architect in the Messaging and Communication Area.
This is why i often need to check, what security Settings exists for a specific Domain.
A lot of this Information is published in Public DNS or HTTPS. So i wrote a PowerShell Script to show this Information.

This Script checks diffrent DNS Records about a Domain - mostly about Mailsecurity Settings.
It checks for the following Information

- DNS Zone Signed (DNSSEC)
- CAA (Certification Authority Authorization)
- MX (MailExchanger)
- MX IP
- MX Reverse Lookup
- Connects to the MX Servers and checks for STARTTLS and shows SMTPBanner and Certificate Information
- SPF (Sender Policy Framework)
- SPF Count (Max 10 Lookups allowed)
- DKIM (DomainKeys Identified Mail)
- DMARC (Domain-based Message Authentication, Reporting and Conformance)
- DMARCAuthorisationRecord
- DANE (DNS-based Authentication of Named Entities)
- BIMI (Brand Indicators for Message Identification)
- MTA-STS (SMTP MTA Strict Transport Security)
- MTA-STS Web (https://mta-sts.domain.tld/.well-known/mta-sts.txt)
- TLSRPT (TLS Reporting)
- Autodiscover
- Lyncdiscover
- Lync/Skype/Teamsfederation
- M365 (Check via Open ID Connect)
- M365 TenantID
- Security.txt https://securitytxt.org/

## How to Install

Find Script in the PowerShell Gallery

```pwsh
#PowerShellGet
Find-Script Get-Mailprotection

#Microsoft.PowerShell.PSResourceGet
Find-PSResource Get-Mailprotection
```

Install Script from the PowerShell Gallery

```pwsh
#PowerShellGet
Install-Script Get-Mailprotection

#Microsoft.PowerShell.PSResourceGet
Install-PSResource Get-Mailprotection
```

## How to use

Output to Console

```pwsh
Get-Mailprotection -Domain domain.tld
```

![Image](Get-Mailprotection01.jpg)

No SMTP Connection to MX Records / No Check for STARTTLS

```pwsh
Get-Mailprotection -Domain domain.tld -SMTPConnect $False
```

![Image](Get-Mailprotection02.jpg)

Return the Result as Object

```pwsh
$ReturnObject = Get-Mailprotection -Domain domain.tld -ReturnObject
```

Return the Result as Object with no Output to Console

```pwsh
$ReturnObject = Get-Mailprotection -Domain domain.tld -ReturnObject -Silent
$ReturnObject
```

![Image](Get-Mailprotection03.jpg)

# Details

## DNS Zone Signed (DNSSEC)

I had to do a DNS over HTTPS (DoH) Query to check this and use the Google Resolver.
If the JSON Returns an AD = True, it means that the DNS Zone is Signed (DNSSEC).

```pwsh
$Domain = "domain.tld"
$URI = "https://dns.google/resolve?name=$Domain&type=NS"	
$json = Invoke-RestMethod -URI $URI
$json
```

## CAA (Certification Authority Authorization)

DNS Certification Authority Authorization
https://en.wikipedia.org/wiki/DNS_Certification_Authority_Authorization

The CAA Record Type returns a List of Certification Authorities that are allowed to issue Certificates for that Domain.

```pwsh
$Domain = "domain.tld"
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=CAA"
$json.Answer.data
```

## MX (MailExchanger)

MX Record defined here [rfc1035](https://datatracker.ietf.org/doc/html/rfc1035)

Get the MX (MailExchanger) DNS Records for a Domain
Will return the Names of the MailExchange (Mailservers) for a Domain

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Type MX -Name domain.tld

#DNS over HTTPS
$URI = "https://dns.google/resolve?name=$Domain&type=MX"
$json = Invoke-RestMethod -URI $URI
$json.Answer.data
```

## MX IP

It will return the IP's of the Mailserver in the MX DNS Record

```pwsh
#Resolve-DnsName
$MXEntry = "mailserver.domain.tld"
Resolve-DnsName -Name $MXEntry

#DNS over HTTPS
$MXEntry = "mailserver.domain.tld"
$URI = "https://dns.google/resolve?name=$MXEntry&type=A"
$json = Invoke-RestMethod -URI $URI
$json.Answer.Data
```

## MX Reverse Lookup

It will return the Name of the IP from the MX Record (Reverse Lookup)
Some Mailservers Require to have a valid Reverse Lookup.

```pwsh
#Resolve-DnsName
Resolve-DnsName -Name <IP>
Resolve-DnsName -Name 104.47.22.10

#DNS over HTTPS
$IP = "104.47.22.10"
$SplitIP = $IP.split(".")
$ReverseLookupIP = $SplitIP[3] + "." + $SplitIP[2] + "." + $SplitIP[1] + "." + $SplitIP[0] + ".in-addr.arpa."
$URI = "https://dns.google/resolve?name=$ReverseLookupIP&type=PTR"
$json = Invoke-RestMethod -URI $URI
$json.Answer.Data
```

## Connects to the MX Servers and checks for STARTTLS and shows Certificate Information

Connect to the Mailserver on Port 25 and send an
>ehlo hostname

Then checks for "STARTTLS" in the Capabilities of the Mailserver.
Also shows the Details of the Certificate

Used most Code from here
https://github.com/BohrenAn/GitHub_PowerShellScripts/blob/main/Exchange/Get-SMTPCertificate.ps1

## SPF (Sender Policy Framework)

SPF exists since 2003 with Updates 2006 and 2014 [rfc7208](https://datatracker.ietf.org/doc/html/rfc7208)

SPF (Sender Policy Framework)
https://en.wikipedia.org/wiki/Sender_Policy_Framework

SPF is a TXT Record that starts with "V=SPF1"
The SPF Record controls what Mailservers are allowed to send Mails in the Name of the Domain
Envelope: Mail from

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Type TXT -Name $Domain | where {$_.Strings -match "V=SPF1"}

#DNS over HTTPS
$Domain = "domain.tld"
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=TXT"
$json.Answer.data | Where-Object {$_ -like "V=SPF1*"}
```

## DKIM (DomainKeys Identified Mail)

It is defined in [rfc6376](https://datatracker.ietf.org/doc/html/rfc6376) from 2011 with updates in [rfc8301](https://datatracker.ietf.org/doc/html/rfc8301) and [rfc8463](https://datatracker.ietf.org/doc/html/rfc8463).

DKIM Records are hard do detect because the Selector can be literally anything.
One way is to try if the Subdomain "_domainkey.domain.tld" gives a Response

```pwsh
$Domain = "domain.tld"
$dnshost = "_domainkey.$Domain"
Resolve-DnsName -Name $dnshost -Type TXT -ErrorAction SilentlyContinue
```

The Selector for Exchange Online are selector1 and selector2

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Name selector1._domainkey.$Domain -Type CNAME -ErrorAction SilentlyContinue
Resolve-DnsName -Name selector2._domainkey.$Domain -Type CNAME -ErrorAction SilentlyContinue

#DNS over HTTPS
$Domain = "domain.tld"
$dnshost1 = "selector1._domainkey." + $Domain
$dnshost2 = "selector2._domainkey." + $Domain

$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost1&type=CNAME"
$json.Answer.data

$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost2&type=CNAME"
$json.Answer.data
```

## DMARC (Domain-based Message Authentication, Reporting and Conformance)

DMARC Exists since 2015 defined in [rfc7489](https://datatracker.ietf.org/doc/html/rfc7489)

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Name _dmarc.$Domain -Type TXT | where {$_.Strings -match "v=DMARC1"}

#DNS over HTTPS
$Domain = "domain.tld"
$dnshost = "_dmarc." + $Domain
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=TXT"
$json.Answer.data | Where-Object {$_ -like "V=DMARC1*"}
```

## DANE (DNS-based Authentication of Named Entities)

Exists since 2015 [rfc8461](https://datatracker.ietf.org/doc/html/rfc8461)

I’ve explained how [DANE works](https://blog.icewolf.ch/archive/2022/01/21/dane-dns-based-authentification-of-named-entities/) in one of my Blog Articles

```pwsh
$Domain = "domain.tld"
$MX = Resolve-DnsName -Type MX -Name domain.tld
Foreach ($MXEntry in $MX)
{
	$TLSAQuery = "_25._tcp.mailserver.domain.tld"
	$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$TLSAQuery&type=TLSA"
	$json.Answer.Data
}
```

## BIMI (Brand Indicators for Message Identification)

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Name default._bimi.$Domain -Type TXT | where {$_.Strings -match "v=BIMI1"}

#DNS over HTTPS
$Domain = "domain.tld"
$dnshost = "default._bimi." + $Domain
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=TXT"
$json.Answer.data | Where-Object {$_ -like "V=BIMI1*"}
```

## MTA-STS (SMTP MTA Strict Transport Security)

Exists since 2018 [rfc8461](https://datatracker.ietf.org/doc/html/rfc8461)

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Name _mta-sts.$Domain -Type TXT | where {$_.Strings -match "v=STSv1"}

#DNS over HTTPS
$DNSHost = "_mta-sts." + $Domain
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$dnshost&type=TXT"
$json.Answer.data | Where-Object {$_ -like "V=STSv1*"}
```

## MTA-STS Web / MTA-STS Policy

Exists since 2018 [rfc8461](https://datatracker.ietf.org/doc/html/rfc8461)

Searches for the MTA-STS Policy
https://mta-sts.domain.tld/.well-known/mta-sts.txt

```pwsh
$Domain = "domain.tld"
$Response = Invoke-WebRequest -URI https://mta-sts.$Domain/.well-known/mta-sts.txt -TimeoutSec 1
$Response.Content
```

## TLSRPT (TLS Reporting)

Exists since 2018 [rfc8461](https://datatracker.ietf.org/doc/html/rfc8461)

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
$TLSRPTQuery = "_smtp._tls.$Domain"
Resolve-DnsName -Name $TLSRPTQuery -Type TXT

#DNS over HTTPS
$Domain = "domain.tld"
$TLSRPTQuery = "_smtp._tls.$Domain"
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$TLSRPTQuery&type=TXT"
$json.Answer.data | Where-Object {$_ -like "V=TLSRPTv1*"}
```

## Autodiscover

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Name autodiscover.$Domain -Type A
Resolve-DnsName -Name autodiscover.$Domain -Type CNAME
Resolve-DnsName _autodiscover._tcp.$Domain -Type SRV

#DNS over HTTPS
$Domain = "domain.tld"
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Autodiscover.$Domain&type=CNAME"
$json.Answer.data
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Autodiscover.$Domain&type=A"
$json.Answer.data
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=_autodiscover._tcp.$Domain&type=SRV"
$json.Answer.data
```

## Lyncdiscover

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Name lyncdiscover.domain.tld -Type A
Resolve-DnsName -Name lyncdiscover.domain.tld -Type CNAME

#DNS over HTTPS
$Domain = "domain.tld"
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Lyncdiscover.$Domain&type=CNAME"
$json.Answer.data
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Lyncdiscover.$Domain&type=A"
$json.Answer.data
```

## Lync/Skype/Teamsfederation

```pwsh
#Resolve-DnsName
$Domain = "domain.tld"
Resolve-DnsName -Name _sipfederationtls._tcp.$Domain -Type SRV

#DNS over HTTPS
$Domain = "domain.tld"
$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=_sipfederationtls._tcp.$Domain&type=SRV"
$json.Answer.data
```

## M365 (Check via Open ID Connect) / TenantID

```pwsh
$Domain = "domain.tld"
$Response = Invoke-WebRequest -UseBasicParsing https://login.windows.net/$Domain/.well-known/openid-configuration
$TenantID = ($Response | ConvertFrom-Json).token_endpoint.Split('/')[3]
```

## Security.txt

Exists since 2022 [rfc9116](https://datatracker.ietf.org/doc/html/rfc9116)

https://securitytxt.org/

Checks for the presence of the security.txt at these two locations

- https://domain.tld/.well-known/security.txt
- https://domain.tld/security.txt

```pwsh
$Domain = "domain.tld"
[bool]$SecurityTXTAvailable = $false
$URI = "https://$Domain/.well-known/security.txt"
try {
	$Response = Invoke-WebRequest -URI $URI -TimeoutSec 1
	If ($Null -ne $Response)
	{
		[bool]$SecurityTXTAvailable = $true
	}
} catch {
	Write-Host "An exception was caught: $($_.Exception.Message)" -ForegroundColor Yellow
}

$URI = "https://$Domain/security.txt"
try {
	$Response = Invoke-WebRequest -URI $URI -TimeoutSec 1
	If ($Null -ne $Response)
	{
		[bool]$SecurityTXTAvailable = $true
	}
} catch {
	Write-Host "An exception was caught: $($_.Exception.Message)" -ForegroundColor Yellow
}
$SecurityTXTAvailable
```

## History

- Version 1.0 / 21.02.2015 Initial Version
- Version 1.1 / 08.04.2015 IDN Domains / Crawled Domains / Unique Domains
- Version 1.2 / 13.04.2015 STARTTLS Support
- Version 1.3 / 26.08.2022 Addet BIMI / DANE / MTA-STS / M365 Checks
- Version 1.4 / 03.10.2022 Addet Reverse Lookup of MX Records / CAA Lookup / TLS-RPT Lookup
- Version 1.5 / 13.10.2022 Fixed Lyncdiscover / Added NS Records & Autodiscover / Minor fixes
- Version 1.6 / 03.04.2023 Addet Parameter -SMTPConnect [true/false] and -ReturnObject [false/true] that is now a PSCustomObject
- Version 1.7 / 16.05.2023 Fixed Lyncdiscover CNAME
- Version 1.8 / 30.09.2023 - Andres Bohren
  - Fixed ReturnObject Nameserver
  - Changed MTA-STSAvailable to MTA-STSAvailable and MTA-STSWeb to MTASTSWeb in ReturnObject
  - ReturnObject of MTASTSWeb is now String
  - ReturnObject of TLSRPT is now String
  - ReturnObject of MXIP is now Array
  - ReturnObject of CAA is now Array
- Version 1.9 / 29.10.2023 - Andres Bohren
  - Fixed Error in Nameserver Output
  - Improved SMTP Connect
  - Addet SMTPBanner
  - Addet SMTPCertificateIssuer
  - Fixed Errorhandling in DANE and NS Lookups
  - Better Errorhandling in SMTPConnect
  - Fixed Autodiscover Lookup
  - Fixed Lyncdiscover Lookup
  - General cleanup of Code
  - Added Security.txt https://securitytxt.org/
  - Added -Silent Parameter
- Version 1.10 / 08.11.2023 - Andres Bohren
  - Fixed STARTTLS and STARTTLS Support in Output and ReturnValue
- Version 1.12
  - Fixed Bug in Detection of Multiple SPF Records
- Version 1.14
  - Moved from Resolve-DNS to DNS over Https (DoH) https://dns.google/resolve
  - Addet Property DMARCAuthorisationRecord
  - Addet Property SPFLookupCount - SPF Record Lookup check if max 10 records are used
  - Fixed some Autodiscover / Lyncdiscover Bugs
  - Changed Parameter -Silent and -Returnobject to Switch

Kind Regards\
Andres Bohren