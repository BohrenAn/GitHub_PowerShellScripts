###############################################################################
# Remove all MAPI Permission from a Mailbox from a specific User
# V0.1 04.10.2021 - Initial Version - Andres Bohren
# V0.2 10.03.2022 - Updates and Cleaning Code - Andres Bohren
# V0.3 28.12.2022 - Updates and Cleaning Code - Andres Bohren
###############################################################################


##############################################################################
# Remove-MAPIPermission
##############################################################################
Function Remove-MAPIPermission {
<# 
.SYNOPSIS
	Simple way of removing MAPI Permissions from a Mailbox for the default Folders (Inbox, Calendar, Notes, Tasks, Contacts)
	Also takes care of the 'FolderVisible' Permission in the Root Folder of the Mailbox.
	
.DESCRIPTION
	Remove MAPI Permission from a specific User
	Remove-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.ch -Trustee erika.mustermann@yourdomain.com -Folder Inbox -RemoveSendOnBehalf $true

.PARAMETER Mailbox
	The mailbox on which the permission will be removed
	
.PARAMETER Trustee
	The User which permissions will be removed

.PARAMETER Folder
	A specific defaultfolder:
	- Inbox
	- Calendar
	- Notes
	- Tasks
	- Contacts

.PARAMETER IncludeSubfolders
	Boolean Value (True/False) if MAPI Permission are removed on all Subfolders

.PARAMETER DeleteRootFolderPermission
	Boolean Value (True/False) to remove MAPI Permission from Root Folder for Trustee

.PARAMETER RemoveSendOnBehalf
	Boolean Value (True/False) if the User will also be removed from the "SendOnBehalf" Permission
	Only works if the User is directly assigned. Will not work if he is in Member of an assigned Group.

	
.EXAMPLE
	Remove-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.ch -User erika.mustermann@yourdomain.com -Folder Inbox
	Remove-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.ch -User erika.mustermann@yourdomain.com -Folder Calendar [-IncludeSubfolders $true] [-RemoveSendOnBehalf $true] [-DeleteRootFolderPermission $true]

#>

	param(
	[parameter(Mandatory=$true)][String]$Mailbox,
	[parameter(Mandatory=$true)][String]$Trustee,
	[parameter(Mandatory=$true)][String]$Folder,
	[bool]$includeSubfolders = $false,
	[bool]$DeleteRootFolderPermission = $false,
	[bool]$RemoveSendOnBehalf = $false
	)

	#Check Exchange Online Connection
	$Return = Test-ExchangeConnection
	If ($Return -eq $false)
	{
		Write-host "Not connected to Exchange or Exchange Online. Please connect first to Exchange or Exchange Online." -ForegroundColor Red
		Break
	}

	#Check if Mailbox exists
	Write-Host "Checking Parameter Mailbox: $Mailbox"
	$MBX = Get-Mailbox -Identity $Mailbox -ErrorAction SilentlyContinue
	If ($Null -eq $MBX)
	{
		Write-Host "Please Enter a valid Mailbox Emailaddress ($Mailbox)" -ForegroundColor Yellow
		Write-Host "The script will be ended right now." -ForegroundColor Yellow
		Break
	}

	#Check if Trustee (exists and has the Right Type)
	Write-Host "Checking Parameter Trustee: $Trustee"
	$FunctionResult = Get-RecipientType -Emailaddress $Trustee
	If ($FunctionResult[0] -eq $false)
	{
		Write-Host "Trustee Recipient not found. Please Enter a valid Trustee Emailaddress ($Trustee)" -ForegroundColor Yellow		
		$readhost = Read-Host "Maybe it's a deleted Mailbox. Do you want to continue? (y/n)[n]?"
		if ($readhost -eq "y")
		{
			#$TrusteeRecipientType = $FunctionResult[1]
			$TrusteePrimarySMTPAddress = $Trustee
			$TrusteeDisplayName = $Trustee
			$TrusteeAlias = $Trustee
		} Else {		
			Write-Host "The script will be ended right now." -ForegroundColor Yellow
			Break
		}
	} else {
		$FunctionResult = Get-RecipientType -Emailaddress $Trustee
		$TrusteeRecipientType = $FunctionResult[1]
		$TrusteePrimarySMTPAddress = $FunctionResult[2]
		$TrusteeDisplayName = $FunctionResult[3]
		$TrusteeAlias = $FunctionResult[4]
	}
	
	#Check Foldertype Input and Parse to foldername
	Write-Host "Checking Parameter Folder: $Folder"
	If ($Folder -ne $null)
	{
		$folderstats = Get-MailboxFolderStatistics -Identity $Mailbox | Where-Object {$_.FolderType -ne "CalendarLogging" -AND $_.FolderType -NotLike "Recoverable*" -AND $_.FolderType -NotLike "Yammer*" -AND $_.FolderType -NotLike "BirthdayCalendar"}		

		switch ($Folder) 
		{
			"Inbox" 
			{
				$InboxObject = $folderstats | Where-Object FolderType -eq "Inbox"
				$CustomFolderName = $InboxObject.Name
			}
			"Calendar"
			{
				$CalendarObject = $folderstats | Where-Object FolderType -eq "Calendar"
				$CustomFolderName = $CalendarObject.Name
			}
			"Notes"
			{
				$NotesObject = $folderstats | Where-Object FolderType -eq "Notes"
				$CustomFolderName = $NotesObject.Name
			}
			"Tasks"
			{
				$TaskObject = $folderstats | Where-Object FolderType -eq "Tasks"
				$CustomFolderName = $TaskObject.Name
		   
			}
			"Contacts"
			{
				$ContactsObject = $folderstats | Where-Object FolderType -eq "Contacts"
				$CustomFolderName = $ContactsObject.Name
			}
			default
			{
				Write-Host "The Parameter -Folder is incorrect. Accepted Values are: 'Inbox', 'Calendar', 'Notes', 'Tasks', 'Contacts'" -foregroundColor Yellow
				Write-Host "The script will be ended right now." -ForegroundColor Yellow
				Break
			}
		}
	}

	###########################################################################
	#Root Folder Permission
	###########################################################################
	If ($DeleteRootFolderPermission -eq $true)
	{
		#Remove View Permission from Root Folder
		Write-Host "Configure RootFolder Permission"

		$FolderPermissions = Get-MailboxFolderPermission $Mailbox":\"
	
		[bool]$RootPermissionFound = $false
		Foreach ($Line in $FolderPermissions)
		{
			If ($Line.User -eq "Standard" -or $Line.User -eq "Default" -or $Line.User -eq "Anonymous")
			{
				If ($Line.AccessRights -eq "FolderVisible")
				{
					Write-Host "Default or Anonymous User has 'FolderVisible' Permission" -ForegroundColor yellow
				}
			} else {
				If ($Line.User.Displayname -eq $TrusteeDisplayName)
				{
					$RootPermissionFound = $true
					#AccessRight
				}
			}
		}
	
		If ($RootPermissionFound -eq $true)
		{
			#Add Prmission
			Write-Host "REMOVE: "$Mailbox":\ > FolderVisible > $TrusteePrimarySMTPAddress" -ForegroundColor Green
			Remove-MailboxFolderPermission -Identity $Mailbox":\" -User $TrusteePrimarySMTPAddress -Confirm:$false | out-null
		}
	}

	###########################################################################
	#Remove Custom Permission from Folder
	###########################################################################
	Write-Host "Configure Folder <$Folder> Permission"
	$FolderPermissions = get-MailboxFolderPermission $Mailbox":\$CustomFolderName"
	#$UserMBXFolderIsNotSet=$true
		
	#Check if Trustee is already in the Trustee Array for that Folder
	Foreach ($Line in $FolderPermissions)
	{
		If ($Line.User.Displayname -eq $TrusteeDisplayName)
		{
			$AccessRight = $Line.AccessRights
			Write-Host "REMOVE: "$Mailbox":\$CustomFolderName > $AccessRight > $TrusteePrimarySMTPAddress" -ForegroundColor Green
			Remove-MailboxFolderPermission -Identity $Mailbox":\$CustomFolderName" -User $Trustee -Confirm:$false | Out-Null
			
			#Exit Foreach
			Break
		}
	}
	

	###########################################################################
	#Subfolders
	###########################################################################
	if ($includeSubfolders -eq $true)
	{
		Write-Host "Configure SubFolders of <$Folder>"
		foreach ($SubFolder in $folderstats)
		{
			if ($SubFolder.identity -match "$Mailbox\\$CustomFolderName\\")
			{
				$NormalizedSubfolder = $SubFolder.identity.replace($Mailbox,$Mailbox +":")
				$NormalizedSubfolder = $NormalizedSubfolder -replace([char]63743,"/")

				$FolderPermissions = get-MailboxFolderPermission $NormalizedSubfolder
				Foreach ($Line in $FolderPermissions)
				{
					If ($Line.User.Displayname -eq $TrusteeDisplayName)
					{
						$AccessRight = $Line.AccessRights
						Write-Host "REMOVE: $NormalizedSubfolder > $AccessRight > $Trustee" -ForegroundColor Green
						Remove-MailboxFolderPermission -Identity $NormalizedSubfolder -User $TrusteePrimarySMTPAddress -Confirm:$false
						
					}
				}
			}
		}
	}

	###########################################################################
	# SendOnBehalf
	###########################################################################
	If ($RemoveSendOnBehalf -eq $true)
	{
		Write-Host "Configure SendOnBehalf"

		#Get Users in Send On Behalf and Add to Array	
		$SOB = Get-Mailbox $Mailbox | Select-Object GrantSendOnBehalfTo
		
		[System.Collections.ArrayList]$SendOnBehalfArr = @()
		Foreach ($Entry in $SOB.GrantSendOnBehalfTo)
		{
			$Recipient = Get-Recipient -Identity "$Entry" | Select-Object DisplayName,Alias,PrimarySmtpAddress
			$PrimarySmtpAddress = ($Recipient.PrimarySmtpAddress).ToString()
			If ($PrimarySmtpAddress -ne $TrusteePrimarySMTPAddress)
			{
				#Add to Array
				$SendOnBehalfArr.Add($PrimarySMTPAddress) | Out-Null
			} 
		}
		
		Write-Host "Remove Send on Behalf to $Mailbox for $TrusteePrimarySMTPAddress" -ForegroundColor Green
		Set-Mailbox $Mailbox -GrantSendOnBehalfTo $SendOnBehalfArr
	}
}
