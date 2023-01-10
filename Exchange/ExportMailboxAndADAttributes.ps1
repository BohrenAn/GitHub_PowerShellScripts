###############################################################################
# Export Mailbox and AD Attributes
# V1.0 23.10.2019 - Andres Bohren - Initial Version
# V1.1 06.01.2023 - Andres Bohren - Minor Fixes
###############################################################################

###############################################################################
# Check-ExchangeConnection
###############################################################################
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

###############################################################################
# Main Script
###############################################################################

#Check if Exchange Connection exists
$Result = Test-ExchangeConnection 
If ($Result -eq $false)
{
	Write-Host "No Exchange Connection found. Aborting Script"
	break
}

#Prepare CSV File
$CSVFilePath = "$PSScriptRoot\MailboxReport.csv"
If (Test-path -Path $CSVFilePath)
{
    Remove-Item $CSVFilePath
}

#Add CSV Header
Add-Content -Path $CSVFilePath -Value ("SamAccountName;UserPrincipalName;WindowsEmailAddress;PrimarySMTPAddress;DisplayName;FirstName;LastName;Title;Department;Manager;StreetAddress;PostalCode;City;CountryOrRegion;Company;Office;Phone;MobilePhone;RecipientTypeDetails;UserAccountControl;AccountDisabled;ResetPasswordOnNextLogon;DistinguishedName;DeliverToMailboxAndForward;ForwardingAddress;ForwardingSmtpAddress;HiddenFromAddressListsEnabled;Alias;WhenMailboxCreated;OU")

#Get Mailboxes and Export Data
$Iterator = 0
Write-Host "Getting Mailboxes..."
$Mailboxes = Get-Mailbox -ResultSize Unlimited
Foreach ($Mailbox in $Mailboxes)
{
	$Iterator = $Iterator + 1
    $Alias = $Mailbox.Alias
    $PrimarySMTPAddress = $Mailbox.PrimarySMTPAddress
	Write-Host "Working on: $PrimarySMTPAddress [$Iterator]" -ForegroundColor Green
	$User = Get-User $Alias
	
	#AD Attributes
	$UserPrincipalName = $User.UserPrincipalName
    $SamAccountName = $User.SamAccountName
	$WindowsEmailAddress = $User.WindowsEmailAddress
	$DisplayName = $User.DisplayName
	$FirstName = $User.FirstName
	$LastName = $User.LastName
	$Title = $User.Title
	$Department = $User.Department
	$Manager = $User.Manager
	$StreetAddress = ($User.StreetAddress).Replace("`n"," ") #Replace NewLine with Space
	$PostalCode = $User.PostalCode
	$City = $User.City
	$CountryOrRegion = $User.CountryOrRegion
	$Company = $User.Company
	$Office = $User.Office
	$Phone = $User.Phone
	$MobilePhone = $User.MobilePhone
	$RecipientTypeDetails = $User.RecipientTypeDetails
	$UserAccountControl = $User.UserAccountControl
	$AccountDisabled = $User.AccountDisabled
	$ResetPasswordOnNextLogon = $User.ResetPasswordOnNextLogon
	$DistinguishedName = $User.DistinguishedName

	#MailboxAttributes
	$DeliverToMailboxAndForward = $Mailbox.DeliverToMailboxAndForward
	$ForwardingAddress = $Mailbox.ForwardingAddress
	$ForwardingSmtpAddress = $Mailbox.ForwardingSmtpAddress
	$HiddenFromAddressListsEnabled = $Mailbox.HiddenFromAddressListsEnabled
	$WhenMailboxCreated = $Mailbox.WhenMailboxCreated
	$OU = $Mailbox.OrganizationalUnit 
	
	Add-Content -Path $CSVFilePath -Value ("$SamAccountName;$UserPrincipalName;$WindowsEmailAddress;$PrimarySMTPAddress;$DisplayName;$FirstName;$LastName;$Title;$Department;$Manager;$StreetAddress;$PostalCode;$City;$CountryOrRegion;$Company;$Office;$Phone;$MobilePhone;$RecipientTypeDetails;$UserAccountControl;$AccountDisabled;$ResetPasswordOnNextLogon;$DistinguishedName;$DeliverToMailboxAndForward;$ForwardingAddress;$ForwardingSmtpAddress;$HiddenFromAddressListsEnabled;$Alias;$WhenMailboxCreated;$OU")

}

Write-Host "Export in File --> $CSVFilePath"
