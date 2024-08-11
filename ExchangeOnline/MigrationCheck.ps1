###############################################################################
# Exchange Health Check
###############################################################################
#Get Exchange Servers
Get-ExchangeServer

#Get Certificates
Get-ExchangeCertificates


#Check Exchange Healh



#Check Recipients
$MailContact = Get-MailContact -resultsize Unlimited
$MailContact | Measure-Object
$Mailuser = Get-Mailuser -resultsize Unlimited
$Mailuser | Measure-Object
$Mailbox = Get-Mailbox -resultsize Unlimited
$Mailbox | Measure-Object
$Recipient = Get-Recipient -resultsize Unlimited
$Recipient | Measure-Object
$User = Get-User -ResultSize Unlimited
$User | Measure-Object

#Check for Empty Groups
$DistributionGroup = Get-DistributionGroup -resultsize Unlimited
Foreach ($Group in $DistributionGroup)
{
    $Members = Get-DistributionGroupMember -Identity $Group
    If ($null -eq $Members)
    {
        Write-Host "$($Group.DisplayName) has no Members" -ForegroundColor Yellow
    }
}

#Check Accounts with Mail set but not Exchange Enabled
Get-ADUser -ldapquery "(objectclass=User)(mail=*)(!Proxyaddresses=*)"

#Check DisplayName for leading or trailing Space

#Check UPN for unsupported Characters (space / ' / umlaute)

#AD User PasswordNotRequired
Get-ADUser -Filter {PasswordNotRequired -eq $true} | Format-Table name, UserPrincipalName

