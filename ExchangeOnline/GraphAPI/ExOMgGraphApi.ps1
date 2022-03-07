###############################################################################
# DEMO of Mailhandling with Migrosoft Graph  (Mail / Calendar / Personal contacts)
# 08.03.2022 V0.1 - Initial Draft - Andres Bohren
###############################################################################

Install-Module Microsoft.Graph
Get-InstalledModule Microsoft.Graph*

#Needed Modules
# -Microsoft.Graph.Mail
# -Microsoft.Graph.Calendar
# -Microsoft.Graph.PersonalContacts


$TenantId = "icewolfch.onmicrosoft.com"
$Scope = "https://graph.microsoft.com/.default" 

#Interactive
Connect-MgGraph -Scopes $scope

#Connect with Certificate
$AppID = "c1a5903b-cd73-48fe-ac1f-e71bde968412" #DelegatedMail
$CertificateThumbprint = "4F1C474F862679EC35650824F73903041E1E5742" #O365Powershell2.cer
Connect-MgGraph -AppId $AppID -CertificateThumbprint $CertificateThumbprint -TenantId $TenantId

###############################################################################
#Get mailFolder
#https://docs.microsoft.com/en-us/graph/api/mailfolder-get?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Application	Mail.ReadBasic.All, Mail.Read, Mail.ReadWrite

$Mailbox = "postmaster@icewolf.ch"
Import-Module Microsoft.Graph.Mail
$Result = Get-MgUserMailFolder -UserId $Mailbox
$Result | Format-List DisplayName, TotalItemCount, UnreadItemCount, id

###############################################################################
#List messages
#https://docs.microsoft.com/en-us/graph/api/user-list-messages?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadBasic, Mail.Read, Mail.ReadWrite
#Application	Mail.ReadBasic.All, Mail.Read, Mail.ReadWrite

Import-Module Microsoft.Graph.Mail
$Mailbox = "postmaster@icewolf.ch"
$Result = Get-MgUserMessage -UserId $Mailbox -MailFolderId $FolderID
$result[0] | Format-List
$result[0] | Format-List ReceivedDateTime, Subject, HasAttachments, BodyPreview

#Paging
$Result = Get-MgUserMessage -UserId $Mailbox -PageSize 5
$result | Format-List ReceivedDateTime, Subject, id
$Result = Get-MgUserMessage -UserId $Mailbox -PageSize 5 -Skip 5
$result | Format-List ReceivedDateTime, Subject, id

#Filter by Subject
$Filter = "Subject eq 'Suchst du etwas anderes'"
$Result = Get-MgUserMessage -UserId $Mailbox -Filter $Filter
$Result | Format-List

#Filter by MessageID
$Filter = "InternetMessageId eq '<TY2PR04MB283043D341CE706923BBE1E9B6319@TY2PR04MB2830.apcprd04.prod.outlook.com>'"
$Result = Get-MgUserMessage -UserId $Mailbox -Filter $Filter
$Result | Format-List

###############################################################################
# Create Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/user-post-messages?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

Import-Module Microsoft.Graph.Mail

$params = @{
	Subject = "Email with New-MgUserMessage"
	Importance = "Low"
	Body = @{
		ContentType = "HTML"
		Content = "Microsoft Graph API is <b>cool</b>!"
	}
	ToRecipients = @(
		@{
			EmailAddress = @{
				Address = "a.bohren@icewolf.ch"
			}
		}
	)
}

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
$Result = New-MgUserMessage -UserId $Mailbox -BodyParameter $params
$Result | Format-List
$MessageId = $Result.ID
$MessageId

###############################################################################
#Update message
#https://docs.microsoft.com/en-us/graph/api/message-update?view=graph-rest-1.0&tabs=powershell
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

Import-Module Microsoft.Graph.Mail

$params = @{
	Subject = "Email with New-MgUserMessage"
	Body = @{
		ContentType = "HTML"
		Content = "Microsoft Graph API is <b>silly</b>!"
	}
    ToRecipients = @(
		@{
			EmailAddress = @{
				Address = "a.bohren@icewolf.ch"
			}
		}
	)
}

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
Update-MgUserMessage -UserId $Mailbox -MessageId $MessageID -BodyParameter $params

###############################################################################
#Add attachment
#https://docs.microsoft.com/en-us/graph/api/message-post-attachments?view=graph-rest-1.0&tabs=powershell
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

Import-Module Microsoft.Graph.Mail
$ContentByte = Get-Content -Path "C:\GIT_WorkingDir\GitHub_PowerShellScripts\ExchangeOnline\GraphAPI\DemoAttachment.docx" -Encoding Byte
$ContentByte = [System.IO.File]::ReadAllBytes('C:\GIT_WorkingDir\GitHub_PowerShellScripts\ExchangeOnline\GraphAPI\DemoAttachment.docx')

$params = @{
	"@odata.type" = "#microsoft.graph.fileAttachment"
	Name = "DemoAttachment.docx"
	ContentBytes = $ContentByte
}

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
New-MgUserMessageAttachment -UserId $Mailbox -MessageId $messageId -BodyParameter $params

###############################################################################
# Delete  Mailbox Message
# https://docs.microsoft.com/en-us/graph/api/message-delete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Mail.ReadWrite
#Delegated (personal Microsoft account)	Mail.ReadWrite
#Application	Mail.ReadWrite

Import-Module Microsoft.Graph.Mail
$Mailbox = "postmaster@icewolf.ch"
Remove-MgUserMessage -UserId $Mailbox -MessageId $messageId

###############################################################################
#message: send
#https://docs.microsoft.com/en-us/graph/api/message-send?view=graph-rest-1.0&tabs=powershell
###############################################################################
Import-Module Microsoft.Graph.Users.Actions
$Mailbox = "postmaster@icewolf.ch"
Send-MgUserMessage -UserId $Mailbox -MessageId $MessageId

###############################################################################
#Send mail
#https://docs.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=powershell
###############################################################################
#Delegated (work or school account)	Mail.Send
#Delegated (personal Microsoft account)	Mail.Send
#Application	Mail.Send

Import-Module Microsoft.Graph.Users.Actions

$params = @{
	Message = @{
		Subject = "Meet for lunch?"
		Body = @{
			ContentType = "Text"
			Content = "The new cafeteria is open."
		}
		ToRecipients = @(
			@{
				EmailAddress = @{
					Address = "a.bohren@icewolf.ch"
				}
			}
		)
		CcRecipients = @(
			@{
				EmailAddress = @{
					Address = "postmaster@icewolf.ch"
				}
			}
		)
	}
	SaveToSentItems = "false"
}

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
Send-MgUserMail -UserId $Mailbox -BodyParameter $params

###############################################################################
#Get calendar
#https://docs.microsoft.com/en-us/graph/api/calendar-get?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.Read
#Delegated (personal Microsoft account)	Calendars.Read
#Application	Calendars.Read
#Group/Teams Calendar only works with Delegated work or School Account

Import-Module Microsoft.Graph.Calendar

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
$Result = Get-MgUserCalendar -UserId $Mailbox
$Result | Format-List


###############################################################################
#List Events
#https://docs.microsoft.com/en-us/graph/api/user-list-events?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.Read, Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.Read, Calendars.ReadWrite
#Application	Calendars.Read, Calendars.ReadWrite

Import-Module Microsoft.Graph.Calendar

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
Get-MgUserEvent -UserId $Mailbox -Property "subject,body,bodyPreview,organizer,attendees,start,end,location" 
Get-MgUserEvent -UserId $Mailbox | Format-List subject,body,bodyPreview,organizer,attendees,start,end,location


###############################################################################
#Create Event
#https://docs.microsoft.com/en-us/graph/api/user-post-events?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.ReadWrite
#Application	Calendars.ReadWrite

Import-Module Microsoft.Graph.Calendar

$params = @{
	Subject = "Let's go for Dinner"
	Body = @{
		ContentType = "HTML"
		Content = "Let's get some nice Food!"
	}
	Start = @{
		DateTime = "2022-03-08T19:00:00"
		TimeZone = "W. Europe Standard Time"
	}
	End = @{
		DateTime = "2022-03-08T22:00:00"
		TimeZone = "W. Europe Standard Time"
	}
	Location = @{
		DisplayName = "Barrys's Restaurant"
	}
	Attendees = @(
		@{
			EmailAddress = @{
				Address = "a.bohren@icewolf.ch"
				Name = "Andres Bohren"
			}
			Type = "required"
		}
	)
}

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
$Result = New-MgUserEvent -UserId $Mailbox -BodyParameter $params
$Result | Format-List
$MessageId = $Result.id
$MessageId


###############################################################################
#Get Event
#https://docs.microsoft.com/en-us/graph/api/event-get?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.Read
#Delegated (personal Microsoft account)	Calendars.Read
#Application	Calendars.Read

Import-Module Microsoft.Graph.Calendar

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
Get-MgUserEvent -UserId $Mailbox -EventId $MessageId -Property "subject,body,bodyPreview,organizer,attendees,start,end,location,locations" 
$Result = Get-MgUserEvent -UserId $Mailbox -EventId $MessageId
$Result | Format-List subject,body,bodyPreview,organizer,attendees,start,end,location,locations

###############################################################################
#Update event
#https://docs.microsoft.com/en-us/graph/api/group-update-event?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.ReadWrite
#Application	Calendars.ReadWrite
Import-Module Microsoft.Graph.Calendar

$params = @{
	Subject = "Let's go for Dinner - Update"
    Recurrence = $null
	ReminderMinutesBeforeStart = 90
	IsOnlineMeeting = $true
	OnlineMeetingProvider = "teamsForBusiness"
	IsReminderOn = $true
	HideAttendees = $false
	Categories = @(
		"Red category"
	)
}

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
Update-MgUserEvent -UserId $Mailbox -EventId $MessageId -BodyParameter $params

###############################################################################
# Delete event
# https://docs.microsoft.com/en-us/graph/api/event-delete?view=graph-rest-1.0&tabs=http
###############################################################################
#Delegated (work or school account)	Calendars.ReadWrite
#Delegated (personal Microsoft account)	Calendars.ReadWrite
#Application	Calendars.ReadWrite

Import-Module Microsoft.Graph.Calendar

# A UPN can also be used as -UserId.
$Mailbox = "postmaster@icewolf.ch"
Remove-MgUserEvent -UserId $Mailbox -EventId $MessageId
