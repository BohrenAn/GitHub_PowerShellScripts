##############################################################################
# Export Mapi Permissions
# V0.1 04.10.2021 - Initial Version - Andres Bohren
# V0.2 10.03.2022 - Updates and Cleaning Code - Andres Bohren
# V0.3 28.12.2022 - Updates and Cleaning Code - Andres Bohren
##############################################################################
Function Export-MAPIPermission
{
<# 
.SYNOPSIS
	Simple way for Exporting MAPI Permissions to a CSV File (with ";" separator)
	
.DESCRIPTION
	Export MAPI Permissions
	Export-MAPIPermission -Mailbox john.doe@yourdomain.com -FilePath C:\temp\john.doe.csv

.PARAMETER Mailbox
	The MAPI Permission for all Folders of the Mailbox will be exportet

.PARAMETER Folder
	A specific default Folder:
	- Inbox
	- Calendar
	- Notes
	- Tasks
	- Contacts
	- SentItems
	- DeletedItems

.PARAMETER ExportDefaultPermissions
	By default this Parameter is set to $True. This means that the Default Folders will be exported.
	If set to $False the Export does not contain "Default" and "Anonymous" User Permissions.

.PARAMETER FilePath
	Full File Path to a File "C:\temp\john.doe.csv"

.EXAMPLE	
	Here are some examples:

	#Export Permissions of all Folders of a Mailbox
	Export-MAPIPermission -Mailbox john.doe@yourdomain.com -FilePath C:\temp\john.doe.csv
	
	#Export Permissions of a specific FolderScope
	Export-MAPIPermission -Mailbox john.doe@yourdomain.com -FilePath C:\temp\john.doe.csv -Folder Calendar

	#Export Permissions of a specific FolderScope without Default Permissions
	Export-MAPIPermission -Mailbox john.doe@yourdomain.com -FilePath C:\temp\john.doe.csv -Folder Calendar -ExportDefaultPermissions $false

#>

	param(
	[parameter(mandatory=$true)][string]$Mailbox,
	[parameter(Mandatory=$false)][string]$Folder,
	[parameter(Mandatory=$false)][bool]$ExportDefaultPermissions = $true,
	[parameter(mandatory=$true)][string]$FilePath
	)

	#Check Exchange Online Connection	
	$Return = Test-ExchangeConnection
	If ($Return -eq $false) 
	{
		Write-host "Not connected to Exchange or Exchange Online. Please connect first to Exchange or Exchange Online." -ForegroundColor Red
		Break
	}

	#Check PARAMETER Filepath
	$Directory = Split-Path $filepath -Parent
	If ((Test-Path $Directory )-eq $false)
	{
		Write-Host "Filepath Directory does not exist" -ForegroundColor Red
		Break
	} else {
		#Check if File exists
		If ((Test-Path $filepath) -eq $true)
		{
			#File alredy Exists
			Write-Host "File already exists." -ForegroundColor Yellow
			$readhost = Read-Host "Do you like to overwrite the File? (y/n)[n]?"
			if ($readhost -eq "n")
			{
				#Stop Script
				Break
			}
		}
	}

	#Check if Mailbox Exists
	If ($Null -eq (Get-Mailbox -Identity $Mailbox -ErrorAction SilentlyContinue))
	{
		#No Mailbox found
		Write-Host "Mailbox not found" -ForegroundColor Red
		break
	}

	#Check Foldertype Input and Parse to foldername
	Write-Host "Checking Parameter Folder: $Folder"
	If ($Null -ne $Folder)
	{
		switch ($Folder) 
		{
			"Inbox"	{}
			"Calendar" {}
			"Notes" {}
			"Tasks" {}
			"Contacts" {}
			"SentItems" {}
			"DeletedItems" {}			
			default
			{
				Write-Host "The Parameter -Folder is incorrect. Accepted Values are: 'Inbox', 'Calendar', 'Notes', 'Tasks', 'Contacts','SentItems','DeletedItems'" -foregroundColor Yellow
				Write-Host "The script will be ended right now." -ForegroundColor Yellow
				Break
			}
		}
	}
	#Get the Mailboxfolders
	Write-Host "Getting folders..."
	If ($Null -ne $Folder)
	{
		Write-host "Exporting FolderScope: $Folder"
		$folderstats = Get-MailboxFolderStatistics -Identity $Mailbox -FolderScope $Folder
	} else {
		$folderstats = Get-MailboxFolderStatistics -Identity $Mailbox | Where-Object {$_.FolderType -ne "Audits" -AND $_.FolderType -ne "CalendarLogging" -AND $_.FolderType -NotLike "Recoverable*"}
	}
	
	


	#Create file to write in
	Set-Content -Path $FilePath -Value "Mailbox;User;AccessRights"

	#Loop through Folders
	foreach ($Line in $folderstats)
	{
		#If the Folder is in the root directory
		if ($Line.FolderType -eq "Root")
		{
			$Foldername = $Line.Identity.replace($Line.Identity, $Mailbox + ":\")
			$FolderId = $Mailbox + ":" + $Line.FolderId
		}
		else 
		{
			$Foldername = $Line.Identity.replace($Mailbox,$Mailbox +":")
			$FolderId = $Mailbox + ":" + $Line.FolderId
		}
	
		
		#[string]$foldername = $foldername -replace([char]63743,"/")
		Write-Host "Working on Folder: $foldername"
		#$FolderPermissions = Get-MailboxFolderPermission -Identity "$foldername"
		#Write-Verbose "FolderID: $FolderID"
		$FolderPermissions = Get-MailboxFolderPermission -Identity "$FolderId"
		
		
		foreach ($FP in $FolderPermissions)
		{	  
			#if default user
			if ($Null -eq $FP.user.adrecipient) 
			{
				$User = $FP.user.DisplayName
				$Accessrights = $FP.accessrights
			}
			else 
			{
				$User = $FP.user.adrecipient.userprincipalname
				$Accessrights = $FP.accessrights
			}
			
			#Write into Export File			
			#Check if Default Permissions should be exported
			If ($ExportDefaultPermissions -eq $false)
			{
				If ($User -eq "Default" -or $User -eq "Anonymous")
				{
					#Do nothing
				} else {
					Add-Content -Path $FilePath -Value "$Foldername;$User;$Accessrights"
				}
			} else {
				Add-Content -Path $FilePath -Value "$Foldername;$User;$Accessrights"
			}
			
		}
	}

	
	$readhost = Read-Host "Do you like to open the exported File? (y/n)[n]?"
	if ($readhost -eq "y")
	{
		Invoke-Item $FilePath
	} Else {
		Write-Host "Please check $FilePath" -ForegroundColor Yellow
	}
}