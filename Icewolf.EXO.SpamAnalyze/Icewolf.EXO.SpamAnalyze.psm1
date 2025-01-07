##############################################################################
# Invoke-SpamAnalyze.ps1
# Get SPAM Detail Info for Specific MessageTraceID in MessageTrace
# V2.0.0 04.05.2021 - Andres Bohren / Initial Version
# V2.0.1 07.05.2021 - Andres Bohren / Bugfixes
# V2.0.2 09.05.2021 - Andres Bohren / Bugfixes
# V2.0.3 16.06.2021 - Andres Bohren / Bugfixes Improvements
# V2.0.4 30.09.2021 - Andres Bohren / Bugfixes Improvements
# V2.0.5 23.12.2021 - Andres Bohren / Bugfixes Improvements
# V2.0.6 01.03.2022 - Andres Bohren / Added dependency Module ExchangeOnlineManagement
# V2.0.7-Alpha 10.03.2022 - Andres Bohren / Added Error Handling (Try / Catch) for DNS over HTTPS Querys
# - DNS Query changed from Cloudflare to Google
#   https://developers.google.com/speed/public-dns/docs/doh
#   https://developers.google.com/speed/public-dns/docs/doh/json
# - Subject is Limited to 20 Characters, so the MessageTraceId is still visible at long Subjects
# V2.0.7-Beta
# - Added diffrent Error Handling (Try / Catch) for DNS over HTTPS Querys
# V2.0.7-Gamma
# - Added Info for Message Event "Send External"
# - Fixed Issue with DNS over HTTPS Querys
# V2.0.7-Delta
# - Requires now ExchangeOnlineModule 3.0.0
# V2.0.8 10.11.2022 - Andres Bohren
# - Requires now ExchangeOnlineModule 3.0.0
# - Addet TentantAllowBlockList checks
# V2.0.9 09.02.2022 - Andres Bohren
# - Addet Reverse Lookup and EOP IP Checks (Special thanks to @SchaedlerDaniel)
# - Checks for Transport Rule with SCL-1
# V2.0.10 13.07.2023
# - Added Check for EOP Relay Pool 40.95.0.0/16
# - Fixes some Issues with DKIM and DMARC Checks
# - General Cleanup of Module
# V2.0.11 17.07.2024
# - Added Try Catch for Get-EOPIP
# - Fixed an Error with DKIM Checks
# V2.0.12 13.10.2024
# - Updated the ReqiredModule ExchangeOnlineManagement to 3.6.0
# V2.0.13 07.01.2025
# - Added Support for Get-MessageTraceV2 / Get-MessageTraceDetailV2
# V2.0.14 07.01.2025
# - Added Support for Get-MessageTraceV2 / Get-MessageTraceDetailV2
# - Updated the ReqiredModule ExchangeOnlineManagement to 3.6.0
##############################################################################
#Requires -Modules ExchangeOnlineManagement

# Create Function with IPaddress that checks is ip is in CIDR Range
# Special thanks to @SchaedlerDaniel
Function Test-IPv4InCIDRRange {
	Param (
		[Parameter(Mandatory = $true, Position = 1)]
		[string]$CIDRNetwork,

		[Parameter(Mandatory = $false, Position = 2)]
		[IPAddress]$TargetIP
	)

	$MaskBits = $CIDRNetwork.Split('/')[1]
	$IP = [System.Net.IPAddress]::Parse($CIDRNetwork.Split('/')[0])

	# Convert the mask to type [IPAddress]
	$mask = ([Math]::Pow(2, $MaskBits) - 1) * [Math]::Pow(2, (32 - $MaskBits))
	$maskbytes = [BitConverter]::GetBytes([UInt32] $mask)
	$DottedMask = [IPAddress]((3..0 | ForEach-Object { [String] $maskbytes[$_] }) -join '.')

	# bitwise AND them together, and you've got the subnet ID
	$lower = [IPAddress] ( $ip.Address -band $DottedMask.Address )

	# We can do a similar operation for the broadcast address
	# subnet mask bytes need to be inverted and reversed before adding
	$LowerBytes = [BitConverter]::GetBytes([UInt32] $lower.Address)
	[IPAddress]$upper = (0..3 | ForEach-Object { $LowerBytes[$_] + ($maskbytes[(3 - $_)] -bxor 255) }) -join '.'

	$f = $lower.GetAddressBytes() | ForEach-Object { "{0:000}" -f $_ }   | & { $ofs = '-'; "$input" }
	$t = $upper.GetAddressBytes() | ForEach-Object { "{0:000}" -f $_ }   | & { $ofs = '-'; "$input" }
	$tg = $TargetIP.GetAddressBytes() | ForEach-Object { "{0:000}" -f $_ }   | & { $ofs = '-'; "$input" }
	return ($f -le $tg) -and ($t -ge $tg)
}

Function Get-EOPIP {
	#Create GUID
	$ClientRequestId = ([guid]::NewGuid()).Guid

	Try {
		#Get Exchange Endpoints
		$uri = "https://endpoints.office.com/endpoints/worldwide?ServiceAreas=Exchange&NoIPv6=true&ClientRequestId=$ClientRequestId"		
		$Result = Invoke-RestMethod -Method GET -uri $uri
	} catch {
		if($_.ErrorDetails.Message) {
			Write-Host $_.ErrorDetails.Message
		} else {
			Write-Host $_
		}
	}

	#EOP IP's
	$EOPAddresses = ($Result | Where-Object {$_.urls -match "mail.protection.outlook.com"}).ips | Sort-Object -Unique
	return $EOPAddresses
}

Function Invoke-SpamAnalyze
{

<#
.SYNOPSIS
	Get SPAM Detail Info for Specific MessageTraceID in MessageTrace

.DESCRIPTION
	Get SPAM Detail Info for Specific MessageTraceID in MessageTrace. Searches automatically in the last 10 Days.

.PARAMETER Recipientaddress
	The Emailaddress of the Recipient

.PARAMETER SenderAddress
	The Emailadress of the Sender

.PARAMETER StartDate
	Optional Parameter: Startdate <DateTime> of MessageTrace (by default current Date - 10)

.PARAMETER EndDate
	Optional Parameter: Enddate <DateTime> of MessageTrace (by default current Date)

.EXAMPLE
.\Invoke-SpamAnalyze -SenderAddress SenderAddress@domain.tld -RecipientAddress RecipientAddress@domain.tld [-StartDate 01/01/2025] [-EndDate 01/10/2025]

.LINK
https://github.com/BohrenAn/GitHub_PowerShellScripts/tree/main/Icewolf.EXO.SpamAnalyze
#>

Param(
	[parameter(Mandatory=$true)][String]$RecipientAddress,
	[parameter(Mandatory=$true)][String]$SenderAddress,
	[parameter(Mandatory=$false)][datetime]$StartDate = (Get-Date).AddDays(-10),
	[parameter(Mandatory=$false)][datetime]$EndDate = (Get-Date)
	)

Begin {
	##############################################################################
	# Connect to Exchange Online
	##############################################################################
	Function Connect-EXO {

		$ConnInfo = Get-ConnectionInformation
		If ($Null -eq $ConnInfo)
		{
			Write-Host "Connect to Exchange Online..." -ForegroundColor Gray
			Connect-ExchangeOnline -ShowBanner:$false
		} else {
			Write-Host "Connection to Exchange Online already exists" -ForegroundColor Green
		}
	}

	##############################################################################
	# Disconnect from Exchange Online
	##############################################################################
	Function Disconnect-EXO
	{
				Write-Host "Disconnect from Exchange Online" -ForegroundColor Gray
				Disconnect-ExchangeOnline -Confirm:$false
	}

	##############################################################################
	# Get-SPAMinfo
	##############################################################################
	Function Get-SPAMinfo {
		Param(
			[parameter(Mandatory=$false)][String]$RecipientAddress,
			[parameter(Mandatory=$false)][String]$SenderAddress,
			[parameter(Mandatory=$true)][String]$MessageTraceId,
			[parameter(Mandatory=$false)][datetime]$StartDate = (Get-Date).AddDays(-10),
			[parameter(Mandatory=$false)][datetime]$EndDate = (Get-Date)
			)

		#Check Get-MessageTracev2, Get-MessageTraceDetailV2
		[bool]$MTV2Available = $False
		[Array]$Commands = Get-Command Get-MessageTracev2, Get-MessageTraceDetailV2
		IF ($Commands.Count -ge 2)
		{
			[bool]$MTV2Available = $True
		}

		Write-Host "Message events:" -ForegroundColor Magenta
		If ($MTV2Available -eq $true)
		{
			Write-Debug "Using Get-MessageTraceDetailV2"
			$MTDetail = Get-MessageTraceDetailV2 -MessageTraceId $MessageTraceId -RecipientAddress $RecipientAddress -SenderAddress $SenderAddress -StartDate $StartDate -EndDate $EndDate | Sort-Object Date
		} else {
			$MTDetail = Get-MessageTraceDetail -MessageTraceId $MessageTraceId -RecipientAddress $RecipientAddress -SenderAddress $SenderAddress -StartDate $StartDate -EndDate $EndDate | Sort-Object Date
		}	
		

		$MTEventFail = $MTDetail | Where-Object {$_.event -eq "Failed"}
		If ($Null -ne $MTEventFail) {
			Write-Host "Failed-Event: " -ForegroundColor Magenta
			Write-Host (" Action:			" +$MTEventFail.action )
			Write-Host
		}
		$MTEventMal = $MTDetail | Where-Object {$_.event -eq "Malware"}
		If ($Null -ne $MTEventMal) {
			Write-Host "Malware-Event: " -ForegroundColor Magenta
			Write-Host (" Action:			" +$MTEventMal.action )
			Write-Host
		}

		#Send External / Extern senden
		$MTEventExternal = $MTDetail | Where-Object {$_.event -match "Extern"}
		If ($Null -ne $MTEventExternal)
		{
			Foreach ($SendExternal in $MTEventExternal)
			{
				Write-Host "Send External: " -ForegroundColor Magenta
				[xml]$xmlE =$MTEventExternal.Data
				#$xmlE.root.MEP

				$Items = $xmle.root.MEP.Count -1
				for ($i=0; $i -lt$Items; $i++)
				{
					$Item = $xmle.root.MEP.Item($i)
					#$Item = $xmle.root.MEP.Item(1)
					$ItemProperty = ($item | Get-Member | Where-Object {$_.MemberType -eq "Property" -and $_.Name -ne "Name"} | Select-Object Name).Name
					$ItemName = $Item.Name
					$ItemValue = $Item.$ItemProperty
					If ($ItemName -eq "CustomData")
					{
						$Blob = $ItemValue.Split(";")
						foreach ($Line in $blob)
						{
							Write-Host " $Line"
						}
					} else {
						Write-Host " $ItemName : $ItemValue"
					}
				}
			}
		}

		$MTEventSPM = $MTDetail | Where-Object {$_.event -eq "Spam"} | Select-Object -uniq
		# SPAM Detail
		If ($Null -ne $MTEventSPM) {
			Write-Host "SPAM-Event: " -ForegroundColor Magenta
			Write-Host (" Action:			" +$MTEventSPM.action )
			Write-Host
			Write-Host "SPAM-Event Details:" -ForegroundColor Magenta
			Write-Host "Anti-spam message headers:	https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-spam-message-headers" -ForegroundColor Cyan
			Write-Host "Spam confidence levels: 	https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/spam-confidence-levels" -ForegroundColor Cyan
			[xml]$xmlS = $MTEventSPM.Data
			$RcptCount  = ($xmlS.root.MEP | Where-Object {$_.Name -eq "RcptCount"})
			$DI		 = ($xmlS.root.MEP | Where-Object {$_.Name -eq "DI"})
			$SCL		= ($xmlS.root.MEP | Where-Object {$_.Name -eq "SCL"})
			$Score		= ($xmlS.root.MEP | Where-Object {$_.Name -eq "Score"})
			$SFV		= ($xmlS.root.MEP | Where-Object {$_.Name -eq "SFV"})
			$ClientIP   = ($xmlS.root.MEP | Where-Object {$_.Name -eq "CIP"})
			$Country	= ($xmlS.root.MEP | Where-Object {$_.Name -eq "Ctry"})
			$HeloString = ($xmlS.root.MEP | Where-Object {$_.Name -eq "H"})
			$ReturnPath = ($xmlS.root.MEP | Where-Object {$_.Name -eq "ReturnPath"})
			$Language   = ($xmlS.root.MEP | Where-Object {$_.Name -eq "Language"})
			Write-Host (" RecipientCount: 		" +$RcptCount.Integer)
			switch ($DI.String) {
				"SB" { $DI = "(SB)	The sender of the message was blocked" }
				"SQ" { $DI = "(SQ)	The message was quarantined" }
				"SD" { $DI = "(SD)	The message was deleted" }
				"SJ" { $DI = "(SJ)	The message was sent to the recipient's Junk Email folder" }
				"SN" { $DI = "(SN)	The message was routed through the higher risk delivery pool" }
				"SO" { $DI = "(SO)	The message was routed through the normal outbound delivery pool" }
			}
			Write-Host (" DI: 				" +$DI)
			# Color for SCL
			switch ($SCL.Integer) {
				-1 { $cSCL = "Green"; $Folder = "Inbox" }
				0 { $cSCL = "Green"; $Folder = "Inbox" }
				1 { $cSCL = "Green"; $Folder = "Inbox" }
				2 { $cSCL = "Green"; $Folder = "Inbox" }
				3 { $cSCL = "Green"; $Folder = "Inbox" }
				4 { $cSCL = "Green"; $Folder = "Inbox" }
				5 { $cSCL = "Yellow"; $Folder = "Junk-E-Mail" }
				6 { $cSCL = "Yellow"; $Folder = "Junk-E-Mail" }
				7 { $cSCL = "Red"; $Folder = "Quarantaine" }
				8 { $cSCL = "Red"; $Folder = "Quarantaine" }
				9 { $cSCL = "Red"; $Folder = "Quarantaine" }
			}
			Write-Host (" SpamConfidenceLevel (SCL):	"+$SCL.Integer +"	Deliver to: " +$Folder +")") -ForegroundColor $cSCL
			Write-Host (" SpamScoreLevel (Score):	"+$Score.Integer )
			switch ($SFV.String)
			{
				"BLK" { $SFV = "(BLK)	Filtering was skipped and the message was blocked because it originated from a blocked sender" }
				"NSPM" { $SFV = "(NSPM)	The message was marked as non-spam and was sent to the intended recipients" }
				"SFE" { $SFV = "(SFE) Filtering was skipped and the message was allowed because it was sent from an address in a user's Safe Senders list"}
				"SKA" { $SFV = "(SKA) The message skipped spam filtering and was delivered to the Inbox because the sender was in the allowed senders list or allowed domains list in an anti-spam policy"}
				"SKB" { $SFV = "(SKB) The message skipped spam filtering and was delivered to the Inbox because the sender was in the allowed senders list or allowed domains list in an anti-spam policy"}
				"SKI" { $SFV = "(SKI) Similar to SFV:SKN, the message skipped spam filtering for another reason (for example, an intra-organizational email within a tenant)"}
				"SKN" { $SFV = "(SKN) The message was marked as non-spam prior to being processed by spam filtering. For example, the message was marked as SCL -1 or Bypass spam filtering by a mail flow rule"}
				"SKQ" { $SFV = "(SKQ) The message was released from the quarantine and was sent to the intended recipients"}
				"SKS" { $SFV = "(SKS)	The message was marked as spam prior to being processed by the content filter" }
				"SPM" { $SFV = "(SPM)	The message was marked as spam by spam filtering" }
			}

			Write-Host (" SpamFilterVerdikt (SFV):	" +$SFV)
			#EOP
			#"40.92.0.0/15" --> 40.92.0.1 - 40.93.255.254
			#"40.107.0.0/16" --> 40.107.0.1 - 40.107.255.254
			#"52.100.0.0/14" --> 52.100.0.1 - 52.103.255.254
			#"104.47.0.0/17" --> 104.47.0.1 - 104.47.127.254
			If ($Null -ne $ClientIP.String -or $ClientIP.String -ne "")
			{
				$IP = [IPAddress] $($ClientIP.String)
				#Check if IP is in EOP CIDR Range
				$EOPIPArray = Get-EOPIP
				foreach ($CIDR in $EOPIPArray)
				{
					If ((Test-IPv4InCIDRRange -TargetIP $IP -CIDRNetwork $CIDR) -eq $True)
					{
						Write-Host (" SenderClientIP (CIP):		" +$ClientIP.String + " --> EOP Address") -ForegroundColor Green
					}
				}
			}

			#EOP relay pool will be in the 40.95.0.0/16 range
			If ($ClientIP.String -like "40.95*")
			{
				Write-Host (" SenderClientIP (CIP):		" +$ClientIP.String + " --> EOP Relay Pool") -ForegroundColor Yellow
			} else {
				Write-Host (" SenderClientIP (CIP):		" +$ClientIP.String)
			}
			Write-Host (" Country (CTRY):		" +$Country.String)
			Write-Host (" HeloString (H):		" +$HeloString.String)
			Write-Host (" ReturnPath:			" +$ReturnPath.String)
			Write-Host (" Language:			" +$Language.String)

			$ReverseDNSLookup = Resolve-DnsName $($ClientIP.String)
			If ($Null -ne $ReverseDNSLookup)
			{
				Write-Host (" ReverseLookup:			" + $ReverseDNSLookup.NameHost)
			} else {
				Write-Host (" ReverseLookup:			 N/A") -ForegroundColor Yellow
			}
			Write-Host

		} Else {
			Write-Host "SPAM-Event: " -ForegroundColor Magenta
			Write-Host (" INFO: 				This mail contains no 'Spam' event ") -ForegroundColor Cyan
			Write-Host
		}
	}
}

##############################################################################
# Main Programm
##############################################################################
Process {
	#Set Window and Buffersize
	$pshost = get-host
	$pswindow = $pshost.ui.rawui
	$LanguageMode = $ExecutionContext.SessionState.LanguageMode
	If ($LanguageMode -eq "Fulllanguage"){
		if ($pswindow.WindowSize.Width -lt 220){
			$newsize = $pswindow.buffersize
			$newsize.height = 8000
			$newsize.width = 220
			$pswindow.buffersize = $newsize
			$newsize = $pswindow.windowsize
			$newsize.width = 180
			$newsize.height = 60
			$pswindow.windowsize = $newsize
		}
	}

	#Call Function to Connect to Exchange Online
	Connect-EXO

	#Check if Messagetrace is available
	Try {
		Get-Command Get-MessageTrace -ErrorAction Stop | Out-Null
		Get-Command Get-MessageTraceV2 -ErrorAction Stop | Out-Null
	} catch {
		Write-Host "No Permission for the Command: Get-MessageTrace or Get-MessageTraceV2. Stopping script."
		#exit
		Break
	}

	#Check Get-MessageTracev2, Get-MessageTraceDetailV2
	[bool]$MTV2Available = $False
	[Array]$Commands = Get-Command Get-MessageTracev2, Get-MessageTraceDetailV2
	IF ($Commands.Count -ge 2)
	{
		[bool]$MTV2Available = $True
	}
	

	#Messagetrace depending on Parameters
	If ($SenderAddress -ne $Null)
	{
		If ($RecipientAddress -ne $Null)
		{
			If ($MTV2Available -eq $true)
			{
				Write-Debug "Using Get-MessageTraceV2"
				$MT = Get-MessageTraceV2 -StartDate $StartDate -EndDate $EndDate -SenderAddress $SenderAddress -RecipientAddress $RecipientAddress
			} else {
				$MT = Get-MessageTrace -StartDate $StartDate -EndDate $EndDate -SenderAddress $SenderAddress -RecipientAddress $RecipientAddress
			}
			
		} else {
			If ($MTV2Available -eq $true)
			{
				Write-Debug "Using Get-MessageTraceV2"
				$MT = Get-MessageTraceV2 -StartDate $StartDate -EndDate $EndDate -SenderAddress $SenderAddress	
			} else {
				$MT = Get-MessageTrace -StartDate $StartDate -EndDate $EndDate -SenderAddress $SenderAddress
			}
		}
	} else {
		#SenderAddress = $Null / RecipientAddress populated
		If ($MTV2Available -eq $true)
		{
			Write-Debug "Using Get-MessageTraceV2"
			$MT = Get-MessageTraceV2 -StartDate $StartDate -EndDate $EndDate -RecipientAddress $RecipientAddress
		} else {
			$MT = Get-MessageTrace -StartDate $StartDate -EndDate $EndDate -RecipientAddress $RecipientAddress
		}	
		
	}
	#$MT | Format-Table Received, SenderAddress, RecipientAddress, Subject, Status, MessageTraceID
	$MT | Select-Object Received, SenderAddress, RecipientAddress, @{label='Subject';expression={$_.Subject.Substring(0,20)}}, Status, MessageTraceID  | Format-Table

	If ($Null -eq $MT)
	{
		Write-Host "No Results in Message Trace found"
	} else {


		#Input MessageTraceID
		$readhost = Read-Host "MessageTraceID?"
		If ($readhost -eq "")
		{
			Write-Host "Not a MessageTraceID... Stopping Script"
		} else {			
			Foreach ($Line in $MT)
			{
				If ($readhost -eq $Line.MessageTraceId)
				{
					$MessageTraceId = $Line.MessageTraceId
					$MTSenderAddress = $Line.Senderaddress
					$MTRecipientAddress = $Line.RecipientAddress
					$MTStatus = $Line.Status
					$MTSubject = $Line.Subject
					$MTReceived = $Line.Received
					$MTMessageID = $Line.MessageID

					#Infos from Message Trace
					Write-Host
					Write-Host "E-Mail Detail:" -ForegroundColor Magenta
					Write-Host " Message ID:		$MTMessageID"
					Write-Host " Received:			$MTReceived"
					Write-Host " Sender:			$MTSenderAddress"
					Write-Host " Recipient:			$MTRecipientAddress"
					Write-Host " Subject:			$MTSubject"
					Write-Host " Status:			$MTStatus"
					Write-Host

					#Check Recipient
					$ExoRecipient = Get-Recipient -Identity $MTRecipientAddress
					#$ExoRecipient
					$RecipientTypeDetails = $ExoRecipient.RecipientTypeDetails

					Write-Host "Recipient Details" -ForegroundColor Magenta
					Write-Host " RecipientTypeDetails:		$RecipientTypeDetails"
					Write-Host

					#Check for Transport Rules with "SCL -1"
					#Get-TransportRule | Where-Object {$_.SetSCL -eq "-1"} | Format-List Name, From,*, SentTo*
					$TransporRules = Get-TransportRule | Where-Object {$_.SetSCL -eq "-1"} | Select-Object Name, From*, SentTo*
					Foreach ($TransportRule in $TransporRules)
					{
						Write-Host "Transport Rule with <SCL-1>" -ForegroundColor Magenta
						Write-Host " Name: $($TransportRule.Name)"
						Write-Host " FromMemberOf: $($TransportRule.FromMemberOf)"
						Write-Host " FromScope: $($TransportRule.FromScope)"
						Write-Host " FromAddressContainsWords: $($TransportRule.FromAddressContainsWords)"
						Write-Host " FromAddressMatchesPatterns: $($TransportRule.FromAddressMatchesPatterns)"
						Write-Host " SentTo: $($TransportRule.SentTo)"
						Write-Host " SentToMemberOf: $($TransportRule.SentToMemberOf)"
						Write-Host " SentToScope: $($TransportRule.SentToScope)"
					}
					Write-Host

					#JunkMailConfiguration of Mailbox
					$SenderDomain = ($SenderAddress.Split("@")[1])
					If ($RecipientTypeDetails -like "*Mailbox")
					{
						$JMC = Get-MailboxJunkEmailConfiguration -Identity $MTRecipientAddress
						If ($NULL -ne $JMC)
						{
							Write-Host "Recipient JunkMailConfiguration" -ForegroundColor Magenta
							Write-Host " TrustedListsOnly:		$($JMC.TrustedListsOnly)"
							Write-Host " ContactsTrusted:		$($JMC.ContactsTrusted)"
							Write-Host

							Write-Host "Check if $MTSenderAddress exists in MAILBOX ($MTRecipientAddress) Trusted-/BlockedSenders list: " -ForegroundColor Magenta
							If ($JMC.TrustedSendersAndDomains -contains $MTSenderAddress)
							{
								Write-Host " USER Junk-E-Mail Config:	Found in 'TrustedSendersAndDomains'" -ForegroundColor Green
							} Else {
								Write-Host " USER Junk-E-Mail Config:	Not found in 'TrustedSendersAndDomains'" -ForegroundColor White
							}

							If ($JMC.BlockedSendersAndDomains -contains $MTSenderAddress)
							{
								Write-Host " USER Junk-E-Mail Config:	Found in 'BlockedSendersAndDomains'" -ForegroundColor Red
							} Else {
								Write-Host " USER Junk-E-Mail Config:	Not found in 'BlockedSendersAndDomains'" -ForegroundColor White
							}
							Write-Host

							Write-Host "Check if $SenderDomain exists in MAILBOX ($MTRecipientAddress) Trusted-/BlockedSenders list: " -ForegroundColor Magenta
							If ($JMC.TrustedSendersAndDomains -contains $SenderDomain)
							{
								Write-Host " USER Junk-E-Mail Config:	Found in 'TrustedSendersAndDomains'" -ForegroundColor Green
							} Else {
								Write-Host " USER Junk-E-Mail Config:	Not found in 'TrustedSendersAndDomains'" -ForegroundColor White
							}

							If ($JMC.BlockedSendersAndDomains -contains $SenderDomain)
							{
								Write-Host " USER Junk-E-Mail Config:	Found in 'BlockedSendersAndDomains'" -ForegroundColor Red
							} Else {
								Write-Host " USER Junk-E-Mail Config:	Not found in 'BlockedSendersAndDomains'" -ForegroundColor White
							}
							Write-Host

						}
					}

					#GLOBALConfig
					Write-Host "Check if $MTSenderAddress exists in GLOBAL Trusted-/BlockedSender list: " -ForegroundColor Magenta
					$GLOBALJunkConfig = Get-HostedContentFilterPolicy

					#Allowed Senders
					If ($GLOBALJunkConfig.AllowedSenders -match $MTSenderAddress)
					{
						Write-Host " GLOBAL EAC SpamFilter:		Found in 'AllowedSenders'" -ForegroundColor Green
					} Else {
						Write-Host " GLOBAL EAC SpamFilter:		Not found in 'AllowedSenders'" -ForegroundColor White
					}

					#Blocked Senders
					If ($GLOBALJunkConfig.BlockedSenders -match $MTSenderAddress)
					{
						Write-Host " GLOBAL EAC SpamFilter:		Found in 'BlockedSenders'" -ForegroundColor Red
					} Else {
						Write-Host " GLOBAL EAC SpamFilter:		Not found in 'BlockedSenders'" -ForegroundColor White
					}
					Write-Host

					Write-Host "Check if $SenderDomain exists in GLOBAL Allowed-/BlockedSenderDomain list: " -ForegroundColor Magenta
					#Allowed Domains
					If ($GLOBALJunkConfig.AllowedSenderDomains.Domain -contains $SenderDomain)
					{
						Write-Host " GLOBAL EAC SpamFilter:		Found in 'AllowedSenderDomains'" -ForegroundColor Green
					} Else {
						Write-Host " GLOBAL EAC SpamFilter:		Not found in 'AllowedSenderDomains'" -ForegroundColor White
					}

					#Allowed Senders
					If ($GLOBALJunkConfig.BlockedSenderDomains.Domain -contains $SenderDomain)
					{
						Write-Host " GLOBAL EAC SpamFilter:		Found in 'BlockedSenderDomains'" -ForegroundColor Red
					} Else {
						Write-Host " GLOBAL EAC SpamFilter:		Not found in 'BlockedSenderDomains'" -ForegroundColor White
					}
					Write-Host

					#Tenant Allow Block List (TABL) SENDER
					Write-Host "Check Tenant Allow Block List - Sender (TABL): " -ForegroundColor Magenta
					$TABLAllowUser = Get-TenantAllowBlockListItems -ListType Sender -Allow -Entry $MTSenderAddress
					If ($Null -eq $TABLAllowUser)
					{
						Write-Host " Not Found in 'TenantAllowBlockList - Allow Addresses'" -ForegroundColor White
					} else {
						Write-Host " Found in 'TenantAllowBlockList - Allow Addresses'" -ForegroundColor White
						Write-Host " Value: $($TABLAllowUser.Value)" -ForegroundColor Yellow
						Write-Host " Action: $($TABLAllowUser.Action)" -ForegroundColor Yellow
						Write-Host " SubmissionID: $($TABLAllowUser.SubmissionID)" -ForegroundColor Yellow
						Write-Host " ListSubType: $($TABLAllowUser.ListSubType)" -ForegroundColor Yellow
						Write-Host " SysManaged: $($TABLAllowUser.SysManaged)" -ForegroundColor Yellow
						Write-Host " LastModifiedDateTime: $($TABLAllowUser.LastModifiedDateTime)" -ForegroundColor Yellow
						Write-Host " ExpirationTime: $($TABLAllowUser.ExpirationDate)" -ForegroundColor Yellow
					}
					$TABLBlockUser = Get-TenantAllowBlockListItems -ListType Sender -Block -Entry $MTSenderAddress
					If ($Null -eq $TABLBlockUser)
					{
						Write-Host " Not Found in 'TenantAllowBlockList - Block Addresses'" -ForegroundColor White
					} else {
						Write-Host " Found in 'TenantAllowBlockList - Block Addresses'" -ForegroundColor White
						Write-Host " Value: $($TABLBlockUser.Value)" -ForegroundColor Yellow
						Write-Host " Action: $($TABLBlockUser.Action)" -ForegroundColor Yellow
						Write-Host " SubmissionID: $($TABLBlockUser.SubmissionID)" -ForegroundColor Yellow
						Write-Host " ListSubType: $($TABLBlockUser.ListSubType)" -ForegroundColor Yellow
						Write-Host " SysManaged: $($TABLBlockUser.SysManaged)" -ForegroundColor Yellow
						Write-Host " LastModifiedDateTime: $($TABLBlockUser.LastModifiedDateTime)" -ForegroundColor Yellow
						Write-Host " ExpirationTime: $($TABLBlockUser.ExpirationDate)" -ForegroundColor Yellow
					}
					$TABLAllowDomain =  Get-TenantAllowBlockListItems -ListType Sender -Allow -Entry $SenderDomain
					If ($Null -eq $TABLAllowDomain)
					{
						Write-Host " Not Found in 'TenantAllowBlockList - Allow Domains'" -ForegroundColor White
					} else {
						Write-Host " Found in 'TenantAllowBlockList - Allow Domains'" -ForegroundColor White
						Write-Host " Value: $($TABLAllowDomain.Value)" -ForegroundColor Yellow
						Write-Host " Action: $($TABLAllowDomain.Action)" -ForegroundColor Yellow
						Write-Host " SubmissionID: $($TABLAllowDomain.SubmissionID)" -ForegroundColor Yellow
						Write-Host " ListSubType: $($TABLAllowDomain.ListSubType)" -ForegroundColor Yellow
						Write-Host " SysManaged: $($TABLAllowDomain.SysManaged)" -ForegroundColor Yellow
						Write-Host " LastModifiedDateTime: $($TABLAllowDomain.LastModifiedDateTime)" -ForegroundColor Yellow
						Write-Host " ExpirationTime: $($TABLAllowDomain.ExpirationDate)" -ForegroundColor Yellow
					}
					$TABLBlockDomain = Get-TenantAllowBlockListItems -ListType Sender -Block -Entry $SenderDomain
					If ($Null -eq $TABLBlockDomain)
					{
						Write-Host " Not Found in 'TenantAllowBlockList - Block Domains'" -ForegroundColor White
					} else {
						Write-Host " Found in 'TenantAllowBlockList - Block Domains'" -ForegroundColor White
						Write-Host " Value: $($TABLBlockDomain.Value)" -ForegroundColor Yellow
						Write-Host " Action: $($TABLBlockDomain.Action)" -ForegroundColor Yellow
						Write-Host " SubmissionID: $($TABLBlockDomain.SubmissionID)" -ForegroundColor Yellow
						Write-Host " ListSubType: $($TABLBlockDomain.ListSubType)" -ForegroundColor Yellow
						Write-Host " SysManaged: $($TABLBlockDomain.SysManaged)" -ForegroundColor Yellow
						Write-Host " LastModifiedDateTime: $($TABLBlockDomain.LastModifiedDateTime)" -ForegroundColor Yellow
						Write-Host " ExpirationTime: $($TABLBlockDomain.ExpirationDate)" -ForegroundColor Yellow
					}
					Write-Host

					#Tenant Allow Block List (TABL) SpoofedSenders
					Write-Host "Check Tenant Allow Block List - SpoofedSenders (TABL): " -ForegroundColor Magenta
					$TABLSpoof = Get-TenantAllowBlockListSpoofItems | Where-Object {$_.SpoofedUser -eq "$SenderDomain"}
					If ($Null -eq $TABLSpoof)
					{
						Write-Host " Not Found in 'TenantAllowBlockList - SpoofedSenders'" -ForegroundColor White
					} else {
						Write-Host " Found in 'TenantAllowBlockList - SpoofedSenders'" -ForegroundColor White
						Write-Host " $($TABLSpoof.SpoofedUser) > $($TABLSpoof.Action)" -ForegroundColor Yellow
					}
					Write-Host

					#Spam Details
					Get-SPAMinfo -RecipientAddress $MTRecipientAddress -SenderAddress $MTSenderAddress -MessageTraceId $MessageTraceId -StartDate $StartDate -EndDate $EndDate

					#DNS Records
					Write-Host "DNS Records of $SenderDomain" -ForegroundColor Magenta


					#Test DNS over HTTP
					$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=google.com&type=NS"
					If (($json | Get-Member -MemberType NoteProperty).count -lt 3)
					{
						Write-Host "This System does not Support DNS over HTTPS" -ForegroundColor Yellow
					} else {

						#NS
						Write-Host "NS" -ForegroundColor Magenta
						try {
							$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$SenderDomain&type=NS"
							[string]$NS = $json.Answer.data
							$NS
						} catch {
							if($_.ErrorDetails.Message) {
								Write-Host $_.ErrorDetails.Message
							} else {
								Write-Host $_
							}
						}

						#MX
						Write-Host "MX" -ForegroundColor Magenta
						try {
							$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$SenderDomain&type=MX"
							[string]$MX = $json.Answer.data
							$MX
						} catch {
							if($_.ErrorDetails.Message) {
								Write-Host $_.ErrorDetails.Message
							} else {
								Write-Host $_
							}
						}

						#SPF
						Write-Host "SPF" -ForegroundColor Magenta
						try {
							$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$SenderDomain&type=TXT"
							$TXT = $json.Answer.data
							$SPF = $TXT | Where-Object {$_ -match "v=spf1"}
							If ($Null -eq $SPF)
							{
								Write-Host "NO SPF Record found" -ForegroundColor Yellow
							} else {
								$SPF
							}
						} catch {
							if($_.ErrorDetails.Message) {
								Write-Host $_.ErrorDetails.Message
							} else {
								Write-Host $_
							}
						}

						#DKIM
						Write-Host "DKIM (Only checking for: selector1/selector2)" -ForegroundColor Magenta
						try {
							$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Selector1._domainkey.$SenderDomain&type=CNAME"
							$DKIM1 = $json.Answer.data
							If ($Null -ne $DKIM1)
							{
								$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$DKIM1&type=TXT"
								$DKIM1 = $json.Answer.data | Where-Object {$_ -match "v=DKIM1"}
							}

							$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=Selector2._domainkey.$SenderDomain&type=CNAME"
							$DKIM2 = $json.Answer.data
							If ($Null -ne $DKIM1)
							{
								$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=$DKIM2&type=TXT"
								$DKIM2 = $json.Answer.data | Where-Object {$_ -match "v=DKIM1"}
							}
							[string]$DKIM = "$DKIM1 $DKIM2"
							If ($DKIM -eq " ")
							{
								Write-Host "NO DKIM Record found" -ForegroundColor Yellow
							} else {
								$DKIM
							}
						} catch {
							if($_.ErrorDetails.Message) {
								Write-Host $_.ErrorDetails.Message
							} else {
								Write-Host $_
							}
						}

						#DMARC
						Write-Host "DMARC" -ForegroundColor Magenta
						try {
							$json = Invoke-RestMethod -URI "https://dns.google/resolve?name=_dmarc.$SenderDomain&type=TXT"
							$DMARC = $json.Answer.data | Where-Object {$_ -match "v=DMARC1"}
							If ($Null -eq $DMARC)
							{
								Write-Host "NO DMARC Record found" -ForegroundColor Yellow
							} else {
								$DMARC
							}
						} catch {
							if($_.ErrorDetails.Message) {
								Write-Host $_.ErrorDetails.Message
							} else {
								Write-Host $_
							}
						}
					}
				}
			}
		}
	}
}

End {
	#Nothing to do here
}
}