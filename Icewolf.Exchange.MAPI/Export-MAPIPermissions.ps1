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
	Export-MAPIPermission -Mailbox john.doe@yourdomain.com -FilePath C:\temp\john.doe.txt

.PARAMETER Mailbox
	The MAPI Permission for all Folders of the Mailbox will be exportet
	
.PARAMETER FilePath
	Full File Path to a File "C:\temp\john.doe.txt"

.EXAMPLE
	Export-MAPIPermission -Mailbox john.doe@yourdomain.com -FilePath C:\temp\john.doe.txt

#>

	param(
	[parameter(mandatory=$true)][string]$Mailbox,
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
		Break
	}

	#Get the Mailboxfolders
	Write-Host "Getting folders..."
	$folderstats = Get-MailboxFolderStatistics -Identity $Mailbox | Where-Object {$_.FolderType -ne "Audits" -AND $_.FolderType -ne "CalendarLogging" -AND $_.FolderType -NotLike "Recoverable*"}
	#Create file to write in
	$sw = new-object system.IO.StreamWriter($FilePath,0)
	$sw.writeline("Mailbox;Trustee;AccessRights")
	foreach ($Line in $folderstats)
	{
		#If the Folder is in the root directory
		if ($Line.FolderType -eq "Root")
		{
			$foldername = $Line.Identity.replace($Line.Identity, $Mailbox + ":\")
		}
		else 
		{
			$foldername = $Line.Identity.replace($Mailbox,$Mailbox +":")
		}
	
		[string]$foldername = $foldername -replace([char]63743,"/")
		Write-Host "Working on Folder: $foldername"
		$folderpermissions = Get-MailboxFolderPermission -Identity "$foldername"
		
		foreach ($fp in $folderpermissions)
		{	  
			#if default user
			if ($Null -eq $fp.user.adrecipient) 
			{
				$Trustee = $fp.user.DisplayName
				$accessrights = $fp.accessrights
			}
			else 
			{
				$Trustee = $fp.user.adrecipient.userprincipalname
				$accessrights = $fp.accessrights
			}
			#Write into File
			$sw.writeline("$foldername;$Trustee;$accessrights") 
		}
	}
	#Cleanup
	$sw.close()
	$sw.dispose()
	
	$readhost = Read-Host "Do you like to open the exported File? (y/n)[n]?"
	if ($readhost -eq "y")
	{
		Invoke-Item $FilePath		
	} Else {
		Write-Host "Please check $FilePath" -ForegroundColor Yellow
	}
}