###############################################################################
# Script to Create Exchange Online Mailuser from CSV File
# 04.10.2023 - Initial Version - Andres Bohren
###############################################################################

###############################################################################
# Function to Create Password
# https://arminreiter.com/2021/07/3-ways-to-generate-passwords-in-powershell/
###############################################################################
Function Get-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [int] $length,
        [int] $amountOfNonAlphanumeric = 1
    )
    #Add-Type -AssemblyName 'System.Web'
    #$PasswordString =  [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)

	#Fix so it works also in PowerShell 7
	$PasswordString = -join ((33..126) * 120 | Get-Random -Count $length | ForEach-Object { [char]$_ })
	
	return $PasswordString
}

###############################################################################
# Open File Dialog
###############################################################################
Function Get-FileDialog {
	PARAM (
		[string]$initialDirectory 
	)
	Write-Host "Choose o365 Migration File" -f Green
	[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.ShowHelp = $true 
	$OpenFileDialog.filter = "All files (*.*)| *.*"
	$show = $OpenFileDialog.ShowDialog()
	If ($Show -eq "OK")	{	
		Return $OpenFileDialog.FileName
	}
}

###############################################################################
#Main Script
###############################################################################

If ($Null -eq (Get-ConnectionInformation))
{
	Write-Host "Connect to ExchangeOnline"
	Connect-ExchangeOnline -ShowBanner:$false
}

#Select CSV File
$CSVFilePath = Get-FileDialog -initialDirectory $PSScriptRoot 

#Import-CSV
Write-Host "Import-CSV..."
$CSV = Import-CSV -Path $CSVFilePath -Encoding UTF8 -Delimiter ";"

#Create OutputFile for Passwords - Will be overwritten every time the Script runs!
Set-Content -Path "$PSScriptRoot\MailuserPwd.csv" -Value ("UserPrincipalName;Password")


Foreach ($Line in $CSV)
{
	$FirstName = $Line.FirstName
	$LastName = $Line.LastName
	$DisplayName = $Line.DisplayName
	$ExternalEmailAddress = $Line.ExternalEmailAddress
	$Alias = $Line.Alias
	$UPN = $Line.UserPrincipalName
	$Password = Get-RandomPassword 14
	[bool]$RemotePowerShellEnabled = $False
	[bool]$ResetPasswordOnNextLogon = $True
	
	Write-Host "Working on: $UPN" -ForegroundColor Green

	#Write Password to File
	Add-Content -Path "$PSScriptRoot\MailuserPwd.csv" -Value ("$UPN;$Password")
	
	#Convert Password to SecureString
	$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
	
	#Add-MailUser
	New-MailUser -Name "$DisplayName" -FirstName $FirstName -LastName $LastName -DisplayName "$DisplayName" -Alias $Alias -ExternalEmailAddress $ExternalEmailAddress -MicrosoftOnlineServicesID $UPN -Password $SecurePassword -RemotePowerShellEnabled $RemotePowerShellEnabled #-ResetPasswordOnNextLogon $ResetPasswordOnNextLogon
	
	#Set ResetPasswordOnNextLogon
	Set-MailUser -Identity $UPN -ResetPasswordOnNextLogon:$ResetPasswordOnNextLogon
}

Write-Host "Passwords are stored in: $PSScriptRoot\MailuserPwd.csv" -ForegroundColor Cyan