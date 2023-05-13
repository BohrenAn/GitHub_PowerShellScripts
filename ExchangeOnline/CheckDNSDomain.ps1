###############################################################################
# CheckDNSDomain.ps1
# Query Public DNS for Mail Related DNS Records
# 20.11.2020 V1.0 Initial Version - Andres Bohren
# 12.05.2023 V1.1 Updated to Google DNS - Andres Bohren
# https://blog.icewolf.ch/archive/2020/11/20/get-mail-related-dns-entrys-with-powershell/
###############################################################################
#CSV Excample
#DomainName;NS;MX;SPF;DKIM;DMARC;Owner;TechContact
#example.com;;;;;;;
#
#For Whois use Sysinternals Whois
#https://docs.microsoft.com/en-us/sysinternals/downloads/whois

###############################################################################
# Open File Dialog
###############################################################################
Function Get-FileDialog {
	PARAM (
	 [string]$initialDirectory
	)
	Write-Host "Choose CSV File" -f Green
	[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.ShowHelp = $true
	$OpenFileDialog.filter = "All files (*.*)| *.*"
	$show = $OpenFileDialog.ShowDialog()
	If ($Show -eq "OK") { 
	 Return $OpenFileDialog.FileName
	}
   }
   
   ###############################################################################
   # MainScript
   ###############################################################################
   
   #Get CSV File
   $CSVFile = Get-FileDialog -InitialDirectory $PSScriptRoot
   
   $CSV = Import-CSV -Path $CSVFile -delimiter ","
   $Int = 0
   Foreach ($Line in $CSV)
   {
			   $Int = $INT + 1
			   $Domain = $Line.DomainName
			   Write-Host "Working On: $Domain [$int]" -ForegroundColor Green
   
			   #NS
			   Write-Host "NS"
			   $json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=NS"
			   [string]$NS = $json.Answer.data
   
			   #MX
			   Write-Host "MX"
			   $json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=MX"
			   [string]$MX = $json.Answer.data
   
			   #SPF
			   Write-Host "SPF"
			   $json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$Domain&type=TXT"
			   $TXT = $json.Answer.data
			   $TXT = $TXT | where {$_ -match "v=spf1"}
			   $SPF = $TXT
   
   
			   #DKIM
			   Write-Host "DKIM"
			   $json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Selector1._domainkey.$Domain&type=CNAME"
			   $DKIM1 = $json.Answer.data
			   $json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Selector2._domainkey.$Domain&type=CNAME"
			   $DKIM2 = $json.Answer.data
			   [string]$DKIM = "$DKIM1 $DKIM2"
   
			   #DMARC
			   Write-Host "DMARC"
			   $json = Invoke-RestMethod -URI "https://dns.google/resolve?name=_dmarc.$Domain&type=TXT"
			   $DMARC = $json.Answer.data
			  
			   #Add to CSV Object
			   $Line.NS = $NS
			   $Line.MX = $MX
			   $Line.SPF = $SPF
			   $Line.DKIM = $DKIM
			   $Line.DMARC = $DMARC
   }
   $CSV | Export-CSV -Path $CSVFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"