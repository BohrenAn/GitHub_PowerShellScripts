# Icewolf.EXO.SpamAnalyze

Hi All,

My Name is Andres Bohren. I am working as a Cloud Architect in the Messaging and Communication Area.
This Module helps you to figure out why a Mail was identified as Spam or Phish.

## Supported

- Exchange Online
- PowerShell 5 / 7
- Tested with
  - Exchange Online (Exchange Online Management 3.x)

## How to Install

```pwsh
# PowerShellGet
Install-Module -Name Icewolf.EXO.SpamAnalyze

# Microsoft.PowerShell.PSResourceGet
Install-PSResource -Name Icewolf.EXO.SpamAnalyze

```

## Built in Help

```pwsh
Get-Help Invoke-SpamAnalyze -Full
```

## Usage

```pwsh
Invoke-SpamAnalyze [-RecipientAddress] <String> [-SenderAddress] <String> [Optional: -StartDate <DateTime>] [Optional: -EndDate <DateTime>] [<CommonParameters>]

#Check Spam (automatic search in the last 10 days)
Invoke-SpamAnalyze -SenderAddress SenderAddress@domain.tld -RecipientAddress RecipientAddress@domain.tld
```

Invoke-SpamAnalyze without -StartDate and -EndDate Parameter

![Image](Icewolf.EXO.SpamAnalyze_01.jpg)

Then select and paste the MessageTraceID

![Image](Icewolf.EXO.SpamAnalyze_02.jpg)

```pwsh
#Check Spam with StartDate and Enddate (max 90 days back but only 10 days between StartDate and -EndDate)
Invoke-SpamAnalyze -SenderAddress SenderAddress@domain.tld -RecipientAddress RecipientAddress@domain.tld -StartDate "01/01/2025" -EndDate "01/10/2025"
```

Invoke-SpamAnalyze with -StartDate and -EndDate Parameter

![Image](Icewolf.EXO.SpamAnalyze_03.jpg)

Then select and paste the MessageTraceID

![Image](Icewolf.EXO.SpamAnalyze_04.jpg)

## Release Notes

V2.0.14 07.01.2025

- Added Support for Get-MessageTraceV2 / Get-MessageTraceDetailV2
- Updated the ReqiredModule ExchangeOnlineManagement to 3.7.0

V2.0.13 07.01.2025

- Added Support for Get-MessageTraceV2 / Get-MessageTraceDetailV2

V2.0.12 13.10.2024

- Updated the ReqiredModule ExchangeOnlineManagement to 3.6.0

V2.0.11 17.07.2024

- Added Try Catch for Get-EOPIPs
- Fixed an Error with DKIM Checks

V2.0.10 13.07.2023

- Added Check for EOP Relay Pool 40.95.0.0/16
- Fixes some Issues with DKIM and DMARC Checks
- General Cleanup of Module

V2.0.9 09.02.2022

- Addet Reverse Lookup and EOP IP Checks (Special thanks to @SchaedlerDaniel)
- Checks for Transport Rule with SCL-1

V2.0.8 11.11.2022

- Requires now ExchangeOnlineManagement 3.0.0
- Addet TentantAllowBlockList checks
