##############################################################################
# Add-MAPIPermission
# V0.1 04.10.2021 - Initial Version - Andres Bohren
# V0.2 10.03.2022 - Updates and Cleaning Code - Andres Bohren
# V0.3 28.12.2022 - Updates and Cleaning Code - Andres Bohren
##############################################################################

Function Add-MAPIPermission {	

<# 
.SYNOPSIS
	Simple way of adding MAPI Permissions to a Mailbox for the default Folders (Inbox, Calendar, Notes, Tasks, Contacts)
	Also takes care of the 'FolderVisible' Permission in the Root Folder of the Mailbox.
	
.DESCRIPTION
	Adding Exchange MAPI Folderpermissions
	Add-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.com -Trustee erika.mustermann@yourdomain.com -AccessRight Reviewer -Folder Inbox [-IncludeSubfolders $false] [-SendOnBehalf $true]

	Folder:
	- Inbox
	- Calendar
	- Notes
	- Tasks
	- Contacts

	AccessRights:		
	-Reviewer
	-Contributor
	-Author
	-Editor
	-NonEditingAuthor
	-Owner
	-PublishingEditor
	-PublishingAuthor

.PARAMETER Mailbox
	The mailbox on which the permission will be set

.PARAMETER Trustee
	Mailboxuser which will be authorised to access the MailboxFolder

.PARAMETER Folder
	A specific defaultfolder:
	- Inbox
	- Calendar
	- Notes
	- Tasks
	- Contacts

.PARAMETER AccessRight
	AccessRights:		
	-Reviewer
	-Contributor
	-Author
	-Editor
	-NonEditingAuthor
	-Owner
	-PublishingEditor
	-PublishingAuthor
	
.PARAMETER IncludeSubfolders
	Boolean Value (True/False) if MAPI Permission is applied on all Subfolders
	
.PARAMETER SendOnBehalf
	Boolean Value (True/False) if the Trustee is also granted the "SendOnBehalf" Permission
	
.EXAMPLE
	Add-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.com -Trustee erika.mustermann@yourdomain.com -AccessRight Reviewer -Folder Calendar [-includeSubfolders $true]
	Add-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.com -Trustee erika.mustermann@yourdomain.com -AccessRight Reviewer -Folder Inbox [-includeSubfolders $false] [-SendOnBehalf $true]
	
#>

	Param(
		[parameter(Mandatory=$true)][String]$Mailbox,
		[parameter(Mandatory=$true)][String]$Trustee,
		[parameter(Mandatory=$true)][String]$Folder,
		[Parameter(Mandatory=$true)][String]$AccessRight,
		[bool]$IncludeSubfolders = $false,
		[bool]$SendOnBehalf = $false
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
	$MBX = Get-Mailbox -Identity $Mailbox
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
		Write-Host "The script will be ended right now." -ForegroundColor Yellow
		Break
	} else {		
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

	#Check Access Right Parameter
	Write-Host "Checking Parameter AccessRight: $AccessRight"
	switch ($AccessRight)
	{ 
		"Reviewer" {} 
		"Contributor" {}
		"Author" {}
		"Editor" {}
		"NonEditingAuthor" {}
		"Owner" {}
		"PublishingEditor" {}
		"PublishingAuthor" {}
		default {
			Write-Host "The Parameter -AccessRight is incorrect. Accepted Values are 'Reviewer', 'Contributor', 'Author', 'Editor', 'NonEditingAuthor', 'Owner', 'PublishingEditor', 'PublishingAuthor' " -ForegroundColor Yellow
			Write-Host "The script will be ended right now." -ForegroundColor Yellow
			Break
		}
	}
 
	###########################################################################
	#Root Folder Permission
	###########################################################################
	Write-Host "Configure RootFolder Permission"
	$FolderPermissions = Get-MailboxFolderPermission $Mailbox":\"
	
	[bool]$RootPermissionFound = $false
	Foreach ($Line in $FolderPermissions)
	{
		If ($Line.User -eq "Standard" -or $Line.User -eq "Default" -or $Line.User -eq "Anonymous")
		{
			If ($Line.AccessRights -eq "FolderVisible")
			{
				Write-Host "Default or Anonymous User has 'FolderVisible' Permission" -foregroundColor yellow
			}
		} else {
			If ($Line.User.Displayname -eq $TrusteeDisplayName)
			{
				$RootPermissionFound = $true
				#AccessRight
			}
			
		}
	}
	
	If ($RootPermissionFound -eq $false)
	{
		#Add Prmission
		Write-Host "ADD: "$Mailbox":\ > FolderVisible > $Trustee" -ForegroundColor Green
		Add-MailboxFolderPermission -Identity $Mailbox":\" -User $Trustee -AccessRights "FolderVisible" | out-null
	}

	###########################################################################
	#Set/Add Custom Permission to Folder
	###########################################################################
	Write-Host "Configure Folder <$Folder> Permission"
	$FolderPermissions = get-MailboxFolderPermission $Mailbox":\$CustomFolderName"
	$UserMBXFolderIsNotSet=$true
		
	#Check if Trustee is already in the Trustee Array for that Folder
	Foreach ($Line in $FolderPermissions)
	{
		If ($Line.User.Displayname -eq $TrusteeDisplayName)
		{
			Write-Host "SET: "$Mailbox":\$CustomFolderName > $AccessRight > $Trustee" -ForegroundColor Green
			Set-MailboxFolderPermission -Identity $Mailbox":\$CustomFolderName" -User $Trustee -AccessRights $AccessRight -WarningAction SilentlyContinue | Out-Null
			
			#Exit Foreach
			$UserMBXFolderIsNotSet=$false
			Break
		}
	}
	
	#Trustee is not in the Trustee List Array for that Folder
	if ($UserMBXFolderIsNotSet)
	{
		Write-Host "ADD: "$Mailbox":\$CustomFolderName > $AccessRight > $Trustee" -ForegroundColor Green
		Add-MailboxFolderPermission -Identity $Mailbox":\$CustomFolderName" -User $Trustee -AccessRights $AccessRight | Out-Null
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
				$UserMBXSubFolderIsNotSet=$true
				Foreach ($Line in $FolderPermissions)
				{
					If ($Line.User.Displayname -eq $TrusteeDisplayName)
					{
						Write-Host "SET: $NormalizedSubfolder > $AccessRight > $Trustee" -ForegroundColor Green
						Set-MailboxFolderPermission -Identity $NormalizedSubfolder -User $Trustee -AccessRights $AccessRight -WarningAction SilentlyContinue | Out-Null
						$UserMBXSubFolderIsNotSet=$false
					}
				}
				if ($UserMBXSubFolderIsNotSet)
				{
					#Folder should not be a Holiday-Calendar/Logging
					switch ($NormalizedSubfolder) 
					{ 
						{$_ -match "Feiertage "} {}
						{$_ -match "Festività "} {}
						{$_ -match " holidays "} {}
						{$_ -match " fériés "} {}
						default {
							Write-Host "ADD: $NormalizedSubfolder > $AccessRight > $Trustee" -ForegroundColor Green
							Add-MailboxFolderPermission -Identity $NormalizedSubfolder -User $Trustee -AccessRights $AccessRight | Out-Null
						}
					}
				}
			}
		}
	}

	###########################################################################
	# SendOnBehalf
	###########################################################################
	#Parameter SendOnBehalf ist True
	If ($SendOnBehalf -eq $true)
	{
		Write-Host "Configure SendOnBehalf"

		#Get Users in Send On Behalf and Add to Array		
		$SOB = Get-Mailbox $Mailbox | Select-Object GrantSendOnBehalfTo
		
		#Check if User is already on the List
		[Bool]$SOBAlreadyMember = $False
		[System.Collections.ArrayList]$SendOnBehalfArr = @()
		Foreach ($Entry in $SOB.GrantSendOnBehalfTo)
		{
			$Recipient = Get-Recipient -Identity "$Entry" | Select-Object DisplayName,Alias,PrimarySmtpAddress
			$PrimarySmtpAddress = ($Recipient.PrimarySmtpAddress).ToString()
			If ($PrimarySmtpAddress -eq $TrusteePrimarySMTPAddress)
			{
				#Trustee is already Member
				$SOBAlreadyMember = $true
				Write-Host "$TrusteePrimarySMTPAddress is already Member of Send on Behalf for $Mailbox" -ForegroundColor Yellow
			} else {
				#Add to Array
				$SendOnBehalfArr.Add($PrimarySMTPAddress) | Out-Null
			}
		}

		If ($SOBAlreadyMember -eq $false)
		{
			$SendOnBehalfArr.Add($Trustee) | Out-Null
			Write-Host "Setting Send on Behalf to $Mailbox for $TrusteePrimarySMTPAddress" -ForegroundColor Green
			Set-Mailbox $Mailbox -GrantSendOnBehalfTo $SendOnBehalfArr
		}
	}
}
