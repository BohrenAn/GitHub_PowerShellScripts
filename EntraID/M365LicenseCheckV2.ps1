###############################################################################
# M365LicenseCheckV2
# V2.0 01.03.2022 - Initial Version - Andres Bohren
# https://blog.icewolf.ch/archive/2021/11/29/hinzufugen-und-entfernen-von-m365-lizenzen-mit-microsoft-graph-powershell.aspx
#
# Due to the high Permissions Restrict Exchange Access to Specific Mailboxes
# Restrict Access to Specific Mailboxes with ApplicationAccessPolicy
# https://blog.icewolf.ch/archive/2021/02/06/limit-microsoft-graph-access-to-specific-exchange-mailboxes.aspx
# New-ApplicationAccessPolicy -AccessRight RestrictAccess -AppId "33554333-f7a0-4d7e-9964-1bd5696ec8e4" -PolicyScopeGroupId "PostmasterGraphRestriction@icewolf.ch" -Description "Restrict this app to members of this Group"
# New-ApplicationAccessPolicy -AccessRight "RestrictAccess" -AppId "33554333-f7a0-4d7e-9964-1bd5696ec8e4" -PolicyScopeGroupId "05c4f6cf-e3e7-40a1-b3b0-f1eb680f78c9" -Description "Restrict this app to members of this Group"
#
# ApplicationAccessPolicy only Restricts the following Scopes
# -Mail.Read 
# -Mail.ReadWrite 
# -Mail.Send 
# -MailboxSettings.Read 
# -MailboxSettings.ReadWrite 
# -Calendars.Read 
# -Calendars.ReadWrite 
# -Contacts.Read 
# -Contacts.ReadWrite 
###############################################################################
#Needed Modules
###############################################################################
# -Microsoft.Graph.Authentication
# -Microsoft.Graph.Users.Action
# -Microsoft.Graph.Mail
# -Microsoft.Graph.Identity.Management
###############################################################################
#Needed Permissions
###############################################################################
#Application Permissions
# -Directory.Read.All
# -Mail.ReadWrite
# -Mail.Send
# -User.Read.All

###############################################################################
# Variables Azure Automation
###############################################################################
#Get Automation Connection / Certification
$Connection = Get-AutomationConnection -Name "AzureRunAsConnection"
$Cert = Get-AutomationCertificate -name "O365Powershell2"
$CertificateThumbprint = $Cert.ThumbPrint

#If you prefer to use AutomationVariables
#$TenantID = Get-AutomationVariable -Name "TenantId"

$AppID = "33554333-f7a0-4d7e-9964-1bd5696ec8e4" #AADLicense
Write-Output "AppID: $AppID"
Write-Output "TenantID: $($Connection.TenantId)"
Write-Output "CertificateThumbprint: $CertificateThumbprint"

###############################################################################
# Variables PowerShell
###############################################################################
#$AppID = "33554333-f7a0-4d7e-9964-1bd5696ec8e4" #AADLicense
#$CertificateThumbprint = "4f1c474f862679ec35650824f73903041e1e5742" #O365Powershell2
#$TenantID = "icewolfch.onmicrosoft.com"

###############################################################################
# Connect-MgGraph
###############################################################################
Write-Output "Connect-MgGraph"
#Connection AzureAutomation
Connect-MgGraph -ClientID $AppID -TenantId $Connection.TenantId -CertificateThumbprint $CertificateThumbprint

#Connect in PowerShell
#Connect-MgGraph -ClientID $AppID -CertificateThumbprint $CertificateThumbprint -TenantId $TenantID

###############################################################################
#Define Minimum Licenses
###############################################################################
$MinLicenses = @{}
$MinLicenses.add( 'MCOEV', "1" )
$MinLicenses.add( 'WINDOWS_STORE', "20" )


###############################################################################
# SKU's an License with MgGraph and PSCustomObject
###############################################################################
#Array with all needed Properties using PSCustomObject
Write-Output "Getting Licenses"
$ArraySKUS = @()
$SKUS = Get-MgSubscribedSku
Foreach ($SKU in $SKUS)
{
    #$ArraySKU = @()
    $AppliesTo = $SKU.AppliesTo
    $CapabilityStatus = $SKU.CapabilityStatus
    $SkuId = $SKU.SkuId
    $SkuPartNumber = $SKU.SkuPartNumber
    $ConsumedUnits = $SKU.ConsumedUnits
    $Enabled = $SKU.PrepaidUnits.Enabled
    $Suspended = $SKU.PrepaidUnits.Suspended
    $Warning = $SKU.PrepaidUnits.Warning
    $SKUObject = [PSCustomObject]@{
        AppliesTo             = $AppliesTo
        CapabilityStatus     = $CapabilityStatus
        SkuId                = $SkuId
        SkuPartNumber        = $SkuPartNumber
        ConsumedUnits        = $ConsumedUnits
        Enabled                = $Enabled
        Suspended            = $Suspended
        Warning                = $Warning
    }
    $ArraySKUS += $SKUObject
}
$ArraySKUS | FT

###############################################################################
#Create HTML Output
###############################################################################
Write-Output "Creating HTML Output"
$Output = @()
$Output += '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
$Output += '<html xmlns="http://www.w3.org/1999/xhtml">'
$Output += '<head>'
$Output += '<title>HTML TABLE</title>'
$Output += '<head></head>'
$Output += '<body>'
$Output += '<table>'
$Output += '<colgroup><col/><col/><col/><col/><col/><col/></colgroup>'
$Output += '<tr><th>SkuId</th><th>SkuPartNumber</th><th>ConsumedUnits</th><th>Enabled</th><th>Suspended</th><th>Warning</th><th>Available</th></tr>'

###############################################################################
#Iterate through Licenses
###############################################################################
Write-Output "Iterate through Licenses"
Foreach ($Line in $ArraySKUS)
{

            $SKUID = $Line.SkuID
            $SKU = $Line.SkuPartNumber
            $ConsumedUnits = $Line.ConsumedUnits
            $PrepaidUnits = $Line.Enabled
            $AvailableUnits = $PrepaidUnits - $ConsumedUnits
            $Suspended = $Line.Suspended
            $Warning = $Line.Warning
            
            $RequiredMinimum = $MinLicenses["$SKU"]

            #Red if ConsumedUnits > PrepaidUnits
            If ($ConsumedUnits -gt $PrepaidUnits)
            {
                $Value = '<tr bgcolor="#ff0000"><td>' + $SKUID + '</td><td>' + $SKU + '</td><td>' + $ConsumedUnits + '</td><td>' + $PrepaidUnits + '</td><td>' + $Suspended + '</td><td>' + $Warning + '</td><td>' +$AvailableUnits + '<td></tr>'
                $Output += $value

            } else {
                If ($RequiredMinimum -ne $null)
                {
                    #Yellow if AvailableUnits < Required Minimum
                    If ($AvailableUnits -lt $RequiredMinimum)
                    {
                        $Value = '<tr bgcolor="#ffff00"><td>' + $SKUID + '</td><td>' + $SKU + '</td><td>' + $ConsumedUnits + '</td><td>' + $PrepaidUnits + '</td><td>' + $Suspended + '</td><td>' + $Warning + '</td><td>' +$AvailableUnits + '<td></tr>'
                        $Output += $value
                    } else {
                        #Yellow if Suspended or Warning otherwise Green
                        If ($Suspended -ne "0" -OR $Warning -ne "0")
                        {
                            $Value = '<tr bgcolor="#ffff00"><td>' + $SKUID + '</td><td>' + $SKU + '</td><td>' + $ConsumedUnits + '</td><td>' + $PrepaidUnits + '</td><td>' + $Suspended + '</td><td>' + $Warning + '</td><td>' +$AvailableUnits + '<td></tr>'
                        } else {
                            $Value = '<tr bgcolor="#00ff00"><td>' + $SKUID + '</td><td>' + $SKU + '</td><td>' + $ConsumedUnits + '</td><td>' + $PrepaidUnits + '</td><td>' + $Suspended + '</td><td>' + $Warning + '</td><td>' +$AvailableUnits + '<td></tr>'
                        }
                        $Output += $value                        
                    }
                } else {
                    #Yellow if Suspended or Warning otherwise Green
                    If ($Suspended -ne "0" -OR $Warning -ne "0")
                    {
                        $Value = '<tr bgcolor="#ffff00"><td>' + $SKUID + '</td><td>' + $SKU + '</td><td>' + $ConsumedUnits + '</td><td>' + $PrepaidUnits + '</td><td>' + $Suspended + '</td><td>' + $Warning + '</td><td>' +$AvailableUnits + '<td></tr>'
                    } else {
                        $Value = '<tr bgcolor="#00ff00"><td>' + $SKUID + '</td><td>' + $SKU + '</td><td>' + $ConsumedUnits + '</td><td>' + $PrepaidUnits + '</td><td>' + $Suspended + '</td><td>' + $Warning + '</td><td>' +$AvailableUnits + '<td></tr>'
                    }
                    $Output += $value
                }
            }
}


$Output += '</table></body></html>'

###############################################################################
#Send Mail
###############################################################################
Write-Output "Sending Mail"

$From = "postmaster@icewolf.ch"
$To = @"
	{
	"emailAddress":{
		"address":"a.bohren@icewolf.ch"
		}
	}
"@
$MessageBody = @{
	content = "$($Output)"
	ContentType = 'html'
	}
$Subject = "M365 License Check V2"

# Create a draft message in the signed-in user's mailbox
$NewMessage = New-MgUserMessage -UserId $From -ToRecipients $To -Subject $Subject -Body $MessageBody
$NewMessage.ToRecipients.EmailAddress

# Send the message
Send-MgUserMessage -UserId $From -MessageId $NewMessage.Id  

###############################################################################
#Disconnect-MgGraph
###############################################################################
Write-Output "Disconnect-MgGraph"
Disconnect-MgGraph