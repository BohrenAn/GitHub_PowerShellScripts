###############################################################################
# Cleanup MobileDevice - Devices Approach
# V1.1 - Updated 10.06.2024 Andres Bohren
# V1.2 - 
###############################################################################
# Requirements:
# Powershell Modules
# - ExchangeOnlineManagement
# Permissions
# - Mail.Send
# - Office 365 Exchange Online: Exchange.ManageAsApp (Service Principal muss EntraID Rolle "Exchange Administrator" haben)
###############################################################################
#Requires -RunAsAdministrator

###############################################################################
# Function WriteLog
###############################################################################
Function Write-Log {
PARAM (
[string]$pLogtext
)
    $pDate =  $(get-date -format "dd.MM.yyyy HH:mm:ss")
    $sw = new-object system.IO.StreamWriter($LogPath, 1)
    $sw.writeline($pDate + " " + $pLogtext)
    $sw.close()
}

###############################################################################
# Main Script
###############################################################################
$LogPath = $PSScriptRoot + "\cleanup.log"
Write-Log "Starting Script"

#Connect-ExchangeOnline
Import-Module ExchangeOnlineManagement
$TenantId = "icewolfch.onmicrosoft.com"
$AppID = "341772e9-4f7a-4444-9b2c-66620d27aec0" #Demo-EXO-RBAC-PS
$CertificateThumbprint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4
Connect-ExchangeOnline -AppID $AppID -CertificateThumbprint $CertificateThumbprint -Organization $TenantId


$StartDate = get-date -f "dd.MM.yyyy HH:mm"

Write-Host "Getting Mobile Devices..."
Write-Log "Getting Mobile Devices..."
$Mobiles = Get-MobileDevice -ResultSize Unlimited
$TotalDevices = $Mobiles.count


$ShortDate = get-date -f "yyyyMMdd"
$CSVFilePath = "$PSScriptRoot\MobileDevice_$ShortDate.csv"
Add-Content -Path $CSVFilePath -Value "DisplayName;DeviceOS;DeviceUserAgent;DeviceModel;ClientType"

$Counter = 0
$Deleted = 0
$ReferenceDate = (Get-Date).AddDays(-30)
Foreach ($Mobile in $Mobiles)
{
    $Counter = $Counter +1 
    $DisplayName = $Mobile.UserDisplayName
    $GUID = $Mobile.Guid
    Write-Host "Working on: $DisplayName [$Counter]" -foregroundColor Green
    
    $Stat = Get-EXOMobileDeviceStatistics -Identity $Guid -ErrorAction SilentlyContinue
    If ($null -eq $Stat)
    {
        Write-Host "Kann gelöscht werden" -ForegroundColor cyan
        Remove-MobileDevice -Identity "$GUID" -Confirm:$false
    } else {

        If ($Stat.LastSuccessSync -lt $ReferenceDate)
        {
            Write-Host "LastSuccessSync: $($Stat.LastSuccessSync)" -foregroundColor Yellow
            Remove-MobileDevice -Identity "$GUID" -Confirm:$false
            $Deleted = $Deleted +1
        } else {
            $DeviceOS = $Mobile.DeviceOS
            $DeviceUserAgent = $Mobile.DeviceUserAgent
            $DeviceModel = $Mobile.DeviceModel
            $ClientType = $Mobile.ClientType
            $UserDisplayName = $Mobile.UserDisplayName

            #WriteLine in CSV
            Add-Content -Path $CSVFilePath -Value "$UserDisplayName;$DeviceOS;$DeviceUserAgent;$DeviceModel;$ClientType"
        }
    }
}
$EndDate = get-date -f "dd.MM.yyyy HH:mm"
Write-Host "Deleted Devices: $Deleted"
Write-Log "Deleted Devices: $Deleted"

#Mailing related variables
[string]$smtpserver = "relay.corp.icewolf.ch"
[string]$smtpfrom = "postmaster@sbb.ch"
[string]$smtpto = "a.bohren@icewolf.ch"
[string]$body = ""

#Send the update Mail 
Write-Host "Send Mail"
Write-Log "Send Mail"

Send-MailMessage -SmtpServer $smtpserver -From $smtpfrom -To $smtpto -Subject "Exchange MobileDevice Cleanup" -Body ("<span style='font-family:Arial;font-size:11pt'>Infos Mobile Device Cleanup:<br />Started: $StartDate <br />Ended: $EndDate <br />Total Mobile Devices: $TotalDevices <br />Deleted Mobile Devices: $Deleted "+ $body +"</span>") -BodyAsHtml

Write-Host "Script finished"
Write-Log "Script finished"
