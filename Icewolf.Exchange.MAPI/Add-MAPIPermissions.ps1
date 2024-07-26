##############################################################################
# Add-MAPIPermission
# V0.1 04.10.2021 - Initial Version - Andres Bohren
# V0.2 10.03.2022 - Updates and Cleaning Code - Andres Bohren
# V0.3 28.12.2022 - Updates and Cleaning Code - Andres Bohren
# V0.3 25.02.2023 - Changed Parameter from Trustee to User - Andres Bohren
# V0.4 12.20.2023 - Added Folders "SentItems" and "DeletedItems" to the Default Folder List - Andres Bohren
##############################################################################

Function Add-MAPIPermission {

<#
.SYNOPSIS
	Simple way of adding MAPI Permissions to a Mailbox for the default Folders (Inbox, Calendar, Notes, Tasks, Contacts)
	Also takes care of the 'FolderVisible' Permission in the Root Folder of the Mailbox.

.DESCRIPTION
	Adding Exchange MAPI Folderpermissions
	Add-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.com -User erika.mustermann@yourdomain.com -AccessRight Reviewer -Folder Inbox [-IncludeSubfolders $false] [-SendOnBehalf $true]

	Folder:
	- Inbox
	- Calendar
	- Notes
	- Tasks
	- Contacts
	- SentItems
	- DeletedItems

	AccessRights:
	- Reviewer
	- Contributor
	- Author
	- Editor
	- NonEditingAuthor
	- Owner
	- PublishingEditor
	- PublishingAuthor

.PARAMETER Mailbox
	The mailbox on which the permission will be set

.PARAMETER User
	Mailboxuser which will be authorised to access the MailboxFolder

.PARAMETER Trustee
	Alias for Parameter User. Mailboxuser which will be authorised to access the MailboxFolder

.PARAMETER Folder
	A specific default Folder:
	- Inbox
	- Calendar
	- Notes
	- Tasks
	- Contacts
	- SentItems
	- DeletedItems

.PARAMETER ExcludeFolders
	A secific SubFolder to Exclude
	john.doe@yourdomain.com:\Inbox\Subfolder1

	Can also be an Array of Folders
	$ExcludeFolders = @("john.doe@yourdomain.com:\Inbox\Subfolder1","john.doe@yourdomain.com:\Inbox\Subfolder2")

.PARAMETER AccessRight
	AccessRights:
	- Reviewer
	- Contributor
	- Author
	- Editor
	- NonEditingAuthor
	- Owner
	- PublishingEditor
	- PublishingAuthor

.PARAMETER IncludeSubfolders
	Boolean Value (True/False) if MAPI Permission is applied on all Subfolders

.PARAMETER SendOnBehalf
	Boolean Value (True/False) if the User is also granted the "SendOnBehalf" Permission

.EXAMPLE
	Add-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.com -User erika.mustermann@yourdomain.com -AccessRight Reviewer -Folder Calendar [-includeSubfolders $true]
	Add-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.com -User erika.mustermann@yourdomain.com -AccessRight Reviewer -Folder Inbox [-includeSubfolders $true] [-ExcludeFolders john.doe@yourdomain.com:\Inbox\Subfolder1] [-SendOnBehalf $true]

	$ExcludeFolders = @("john.doe@yourdomain.com:\Inbox\Subfolder1","john.doe@yourdomain.com:\Inbox\Subfolder2")
	Add-MAPIPermission.ps1 -Mailbox john.doe@yourdomain.com -User erika.mustermann@yourdomain.com -AccessRight Reviewer -Folder Inbox [-includeSubfolders $true] [-ExcludeFolders $ExcludeFolders] [-SendOnBehalf $true]

#>

	Param(
		[parameter(Mandatory=$true)][String]$Mailbox,
		[parameter(Mandatory=$true)][Alias("Trustee")][String]$User,
		[parameter(Mandatory=$true)][ValidateSet("Inbox", "Calendar", "Notes", "Tasks", "Contacts", "SentItems", "DeletedItems")][String]$Folder,
		[parameter(Mandatory=$false)][Array]$ExcludeFolders,
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

	#Check if User (exists and has the Right Type)
	Write-Host "Checking Parameter User: $User"
	$FunctionResult = Get-RecipientType -Emailaddress $User
	If ($FunctionResult[0] -eq $false)
	{
		Write-Host "User Recipient not found. Please Enter a valid User Emailaddress ($User)" -ForegroundColor Yellow
		Write-Host "The Script will be ended right now." -ForegroundColor Yellow
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
		$Folderstats = Get-MailboxFolderStatistics -Identity $Mailbox | Where-Object {$_.FolderType -ne "CalendarLogging" -AND $_.FolderType -NotLike "Recoverable*" -AND $_.FolderType -NotLike "Yammer*" -AND $_.FolderType -NotLike "BirthdayCalendar"}

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
			"SentItems"
			{
				$ContactsObject = $folderstats | Where-Object FolderType -eq "SentItems"
				$CustomFolderName = $ContactsObject.Name
			}
			"DeletedItems"
			{
				$ContactsObject = $folderstats | Where-Object FolderType -eq "DeletedItems"
				$CustomFolderName = $ContactsObject.Name
			}
			default
			{
				Write-Host "The Parameter -Folder is incorrect. Accepted Values are: 'Inbox', 'Calendar', 'Notes', 'Tasks', 'Contacts','SentItems','DeletedItems'" -foregroundColor Yellow
				Write-Host "The script will be ended right now." -ForegroundColor Yellow
				Break
			}
		}
	}

	#Check $ExcludeFolder Variable
	#Check Format: Mailbox:\Folder\Subfolder
	Write-Host "Checking Parameter ExcludeFolder: $ExcludeFolders"
	Foreach ($ExcludeFolderEntry in $ExcludeFolders)
	{
		Write-Debug "DEBUG: $ExcludeFolderEntry"
		If (($ExcludeFolderEntry -match "^.+:\\.+\\.+$") -eq $false)
		{
			Write-Host "The Parameter -ExcludeFolder is incorrect. Correct Syntax: Mailbox:\Folder\Subfolder" -foregroundColor Yellow
			Write-Host "The script will be ended right now." -ForegroundColor Yellow
			break
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
		Write-Host "ADD: "$Mailbox":\ > FolderVisible > $User" -ForegroundColor Green
		Add-MailboxFolderPermission -Identity $Mailbox":\" -User $User -AccessRights "FolderVisible" | out-null
	}

	###########################################################################
	#Set/Add Custom Permission to Folder
	###########################################################################
	Write-Host "Configure Folder <$Folder> Permission"
	$FolderPermissions = Get-MailboxFolderPermission $Mailbox":\$CustomFolderName"
	$UserMBXFolderIsNotSet=$true

	#Check if User is already in the User Array for that Folder
	Foreach ($Line in $FolderPermissions)
	{
		If ($Line.User.Displayname -eq $TrusteeDisplayName)
		{
			Write-Host "SET: "$Mailbox":\$CustomFolderName > $AccessRight > $User" -ForegroundColor Green
			Set-MailboxFolderPermission -Identity $Mailbox":\$CustomFolderName" -User $User -AccessRights $AccessRight -WarningAction SilentlyContinue | Out-Null

			#Exit Foreach
			$UserMBXFolderIsNotSet=$false
			Break
		}
	}

	#User is not in the User List Array for that Folder
	if ($UserMBXFolderIsNotSet)
	{
		Write-Host "ADD: "$Mailbox":\$CustomFolderName > $AccessRight > $User" -ForegroundColor Green
		Add-MailboxFolderPermission -Identity $Mailbox":\$CustomFolderName" -User $User -AccessRights $AccessRight | Out-Null
	}

	###########################################################################
	#Subfolders
	###########################################################################
	if ($includeSubfolders -eq $true)
	{
		Write-Host "Configure SubFolders of <$Folder>"
		foreach ($SubFolder in $folderstats)
		{
			$SubFolderIdentity = $SubFolder.identity
			if ($SubFolderIdentity -match "$Mailbox\\$CustomFolderName\\")
			{
				#Check for Exclude Folder
				$ExcludeFolderMatch = $False
				Foreach ($ExcludeFolderEntry in $ExcludeFolders)
				{
					[regex]$pattern = ":\\"
					$ExcludeFolderEntry2 = $pattern.replace($ExcludeFolderEntry, "\", 1) #Replace first ":\" with "\"

					Write-Verbose "ExcludeFolderEntry: $ExcludeFolderEntry2 > SubFolderIdentity $SubFolderIdentity"

					If ("$ExcludeFolderEntry2" -eq "$SubFolderIdentity")
					{
						$ExcludeFolderMatch = $True
					}
				}

				If ($ExcludeFolderMatch -eq $true)
				{
					Write-Host "Skipping excluded Folder: $SubFolderIdentity" -ForegroundColor Yellow
				} else {

					$Foldername = $Subfolder.Identity.replace($Mailbox,$Mailbox +":")
					$FolderId =  $Mailbox + ":" + $SubFolder.FolderId

					$FolderPermissions = Get-MailboxFolderPermission $FolderId
					$UserMBXSubFolderIsNotSet=$true
					Foreach ($Line in $FolderPermissions)
					{
						If ($Line.User.Displayname -eq $TrusteeDisplayName)
						{
							Write-Host "SET: $Foldername > $AccessRight > $User" -ForegroundColor Green
							#Set-MailboxFolderPermission -Identity $NormalizedSubfolder -User $User -AccessRights $AccessRight -WarningAction SilentlyContinue | Out-Null
							Set-MailboxFolderPermission -Identity $FolderId -User $User -AccessRights $AccessRight -WarningAction SilentlyContinue | Out-Null
							$UserMBXSubFolderIsNotSet=$false
						}
					}
					if ($UserMBXSubFolderIsNotSet)
					{
						#Folder should not be a Holiday-Calendar/Logging
						switch ($Foldername)
						{
							{$_ -match " holidays "} {Write-Verbose "Holiday Calendar ENG"} #ENG
							{$_ -match "Feiertage "} {Write-Verbose "Holiday Calendar GER"} #GER
							{$_ -match " fériés "} {Write-Verbose "Holiday Calendar FRA"} #FRA
							{$_ -match "Festività "} {Write-Verbose "Holiday Calendar ITA"} #ITA
							{$_ -match "Feriados "} {Write-Verbose "Holiday Calendar PRT"} #PRT
							{$_ -match " festivos "} {Write-Verbose "Holiday Calendar ESP"} #ESP
							{$_ -match "Feestdagen "} {Write-Verbose "Holiday Calendar NLD"} #NLD
							{$_ -match "helgdagar "} {Write-Verbose "Holiday Calendar SWE/FIN"} #SWE/FIN
							{$_ -match "Heilagdagar "} {Write-Verbose "Holiday Calendar NOR"} #NOR
							{$_ -match " święta"} {Write-Verbose "Holiday Calendar POL"} #POL
							{$_ -match "Svátky "} {Write-Verbose "Holiday Calendar CZE"} #CZE
							{$_ -match " ünnepei"} {Write-Verbose "Holiday Calendar HUN"} #HUN
							{$_ -match " sviatky"} {Write-Verbose "Holiday Calendar SVK"} #SVK
							{$_ -match " prazniki"} {Write-Verbose "Holiday Calendar SVN"} #SVN
							{$_ -match "Blagdani "} {Write-Verbose "Holiday Calendar HRV/BIH"} #HRV/BIH
							default {
								Write-Verbose "NO Holiday Calendar"
								Write-Host "ADD: $Foldername > $AccessRight > $User" -ForegroundColor Green
								Add-MailboxFolderPermission -Identity $FolderId -User $User -AccessRights $AccessRight | Out-Null
							}
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
				#User is already Member
				$SOBAlreadyMember = $true
				Write-Host "$TrusteePrimarySMTPAddress is already Member of Send on Behalf for $Mailbox" -ForegroundColor Yellow
			} else {
				#Add to Array
				$SendOnBehalfArr.Add($PrimarySMTPAddress) | Out-Null
			}
		}

		If ($SOBAlreadyMember -eq $false)
		{
			$SendOnBehalfArr.Add($User) | Out-Null
			Write-Host "SET Send on Behalf to $Mailbox for $TrusteePrimarySMTPAddress" -ForegroundColor Green
			Set-Mailbox $Mailbox -GrantSendOnBehalfTo $SendOnBehalfArr
		}
	}
}
