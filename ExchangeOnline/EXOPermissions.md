# Exchange Online Permissions

Here are the commands for FullAccess, SendAs and SendOnBehalf Permissions in Exchange Online.

## Connect to Exchange Online

```pwsh
#Install-Module ExchangeOnlineManagement
Connect-ExchangeOnline -ShowBanner:$false
```

## Full Access
```pwsh
###############################################################################
# FullAccess
###############################################################################
$Mailbox = "demo@example.com"
$User = "user@example.com"

#Get FullAccess Permissions
Get-MailboxPermission  -Identity $Mailbox | where { ($_.AccessRights -eq "FullAccess") -and ($_.IsInherited -eq $false) -and -not ($_.User -like "NT AUTHORITY\SELF") } | ft -AutoSize

#Add FullAccess Permissions
Add-MailboxPermission -Identity $Mailbox -User $User -AccessRights FullAccess -AutoMapping $true

#Remove FullAccess Permissions 
Remove-MailboxPermission -Identity $Mailbox -User $User -AccessRights FullAccess
```

## SendAs
```pwsh
###############################################################################
# SendAs
###############################################################################
$Mailbox = "demo@example.com"
$Trustee = "user@example.com"

#Get SendAs Permissions
Get-RecipientPermission  -Identity $Mailbox | where { ($_.AccessRights -eq "SendAs") -and ($_.IsInherited -eq $false) -and -not ($_.Trustee -like "NT AUTHORITY\SELF") } | ft -AutoSize

#Add SendAs Permissions
Add-RecipientPermission -Identity $Mailbox -Trustee $Trustee -AccessRights SendAs

#Remove SendAs Permissions
Remove-RecipientPermission -Identity $Mailbox -Trustee $Trustee -AccessRights SendAs
```

## SendOnBehalf
```pwsh
###############################################################################
# Send on Behalf
###############################################################################
$Mailbox = "demo@example.com"

#Get SendOnBehalf Permissions
Get-Mailbox -Identity $Mailbox | select -ExpandProperty GrantSendOnBehalfTo

#Add SendOnBehalf Permissions
Set-Mailbox -Identity $Mailbox -GrantSendOnBehalfTo "User1,User2,User3"

#Remove SendOnBehalf Permissions
Set-Mailbox -Identity $Mailbox -GrantSendOnBehalfTo $Null
```
