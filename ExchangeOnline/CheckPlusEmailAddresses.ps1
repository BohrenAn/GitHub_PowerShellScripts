###############################################################################
# CheckPlusEmailAddresses.ps1
# Checks the Mailboxes for "+" Character in SMTP EmailAddresses
# 22.08.2021 Initial Version - Andres Bohren
# 13.09.2021 Using now the Get-EXOMailbox - Andres Bohren
###############################################################################
#Requires -Modules ExchangeOnlineManagement

Import-Module ExchangeOnlineManagement

#Check if Exchange Online Session is open or Connect-ExchangeOnline
$session = Get-PSSession | Where-Object {$_.ConfigurationName -eq "Microsoft.Exchange" -AND $_.Computername -eq "outlook.office365.com"}
If ($Null -eq $session)
{
	#No ExchangeOnline Session found > Connect-ExchangeOnline
	Connect-ExchangeOnline
} else {
	If ($Session.State -eq "Broken")
	{
		{
			Write-Host "WARNING: Session broken. Trying to Reconnect..."
			Disconnect-ExchangeOnline -Confirm:$False			
			Connect-ExchangeOnline 
		}
	}
}

#Getting Mailboxes
Write-Host "Getting Mailboxes..."
$Mailboxes = Get-EXOMailbox -ResultSize Unlimited

#Output File in ScriptDirectory
$OutputFile = $PSScriptRoot + "\CheckPlusEmailAddresses.csv"
Write-Host "OutputFile: $OutputFile"

#Delete File if it Exists
If (Test-Path -Path $OutputFile)
{
	Remove-Item $OutputFile
}

#Header Anlegen
Add-Content -Path $OutputFile -Value ("PrimarySMTPAddress;WarningEmailAddress") -Encoding UTF8

#Loop through Mailboxes
$Int = 0
Foreach ($MBX in $Mailboxes)
{
	$Int = $Int +1
	$PrimarySMTPAddress = $MBX.PrimarySMTPAddress
	Write-Host "Working on: $PrimarySMTPAddress [$int]" -ForeGroundColor Green
	
	#Get Emailadresses
	$ArrayEmailAddresses = $MBX.EmailAddresses
	Foreach ($Entry in $ArrayEmailAddresses)
	{
		$Emailaddress = $Entry
		#Only interested in SMTP Addresses
		If ($Emailaddress -Match "SMTP:")
		{			
			Write-Host "SMTP Address found: $Emailaddress"
			
			#Check for + Character
			If ($Emailaddress -match "\+")
			{				
				Write-Host "Plus Character in SMTP Address found" -ForeGroundColor Red
				Add-Content -Path $OutputFile -Value ("$PrimarySMTPAddress;$Emailaddress") -Encoding UTF8
			}
		}
	}
}

Write-Host "Result can be found in $OutputFile" -ForegroundColor Cyan