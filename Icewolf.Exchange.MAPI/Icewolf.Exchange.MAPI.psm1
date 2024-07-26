###############################################################################
# Icewolf.Exchange.MAPI Powershell Module
# Contains following Functions
# - Export-MAPIPermissions
# - Add-MAPIPermissions
# - Remove-MAPIPermissions
# V0.1 30.04.2020 - Initial Version - Andres Bohren a.bohren@icewolf.ch
# V0.2 21.02.2022 - Consolidated Code - Andres Bohren a.bohren@icewolf.ch
# V0.3 28.12.2022 - Updates and Cleaning Code - Andres Bohren
# V0.4 12.20.2023 - Added Folders "SentItems" and "DeletedItems" to the Default Folder List - Andres Bohren
###############################################################################

#Import Scripts
#Write-Host "Loading Module..."

#Loading *.ps1 Scripts in current Directory
try {
	$Scriptfiles = Get-childitem -path "$PSScriptRoot" -name -Filter "*.ps1"
	Foreach ($Scriptfile in $Scriptfiles)
	{
		. ($PSScriptRoot + "\" + $Scriptfile)
	}
} catch {
	Write-Host "ERROR: $($_.Exception.ToString())" -ForegroundColor Red
}


##############################################################################
# Check-RecipientType
# Check for wrong entered Recipients / Trustees (e.g. contatcs)
##############################################################################
Function Get-RecipientType {

	Param(
	[parameter(Mandatory=$true)][String]$Emailaddress
	)

	Try {
		#Define Return Array with 4 values
		$returnArray = @()
		$returnArray += $false #Is mailbox found - Default value false
		$returnArray += "" #RecipientTypeDetails
		$returnArray += "" #Primarysmtpaddress
		$returnArray += "" #DisplayName
		$returnArray += "" #Alias

		$Result = Get-Recipient -Identity $Emailaddress -ErrorAction SilentlyContinue| Select-Object RecipientTypeDetails, Primarysmtpaddress, DisplayName, Alias

		If ($Null -eq $result)
		{
			#No Object found
			#Write-Host "no object found"
			$returnArray[0] = $false
		} else {
			#Object found - check if it is User Mailbox or Mail Enabled Security Group (Universal)
			if ($result.RecipientTypeDetails -eq "UserMailbox" -or $result.RecipientTypeDetails -eq "MailUniversalSecurityGroup")
			{
				$returnArray[0] = $true
				$returnArray[1] = $Result.RecipientTypeDetails
				$returnArray[2] = ($Result.Primarysmtpaddress).ToString()
				$returnArray[3] = $Result.DisplayName
				$returnArray[4] = $Result.Alias
			} else {
				#Write-host "not a user Mailbox $result"
				$returnArray[0] = $false
			}
		}
	} catch {
		write-host "ERROR: An error has occurred: `r`n $_.Exception.Message" -ForegroundColor Red
	}
	return $returnarray
}

##############################################################################
# Get-EmailaddressFromAlias
# Input: Alias / Return: PrimarySmtpAddress
##############################################################################
Function Get-EmailaddressFromAlias {
	Param(
	[parameter(Mandatory=$true)][String]$Alias
	)

	$Recipient = Get-Recipient $Alias
	$PrimarySmtpAddress = ($Recipient.PrimarySmtpAddress).ToString()
	Return $PrimarySmtpAddress
}

##############################################################################
# Check-ExchangeConnection
##############################################################################
Function Test-ExchangeConnection {
	try {
		$MBX = Get-Mailbox -ResultSize 1 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
		If ($null -ne $MBX)
		{
			$OrginatingServer = $MBX.OriginatingServer
			If ($OrginatingServer -like "*PROD.OUTLOOK.COM")
			{
				Write-Verbose "Connected with Exchange Online"
			} else {
				Write-Verbose "Connected with Exchange OnPrem"
			}

			#Exchange Connection found
			return $true
		} else {
			return $false
		}
	} catch {
		#Write-Host $_.Exception.Message -ForegroundColor Red
		return $false
	}
}
