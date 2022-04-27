###############################################################################
# Check-PendingReboot.ps1
# Andres Bohren / www.icewolf.ch / blog.icewolf.ch / a.bohren@icewolf.ch
# Version 1.0 / 03.06.2020 - Initial Version - Andres Bohren
# Version 1.1 / 27.04.2022 - Updated Script - Andres Bohren
# https://blog.icewolf.ch/archive/2020/07/03/check-for-pending-reboot-with-powershell.aspx
###############################################################################
<#
.SYNOPSIS
    This Script checks diffrent Registry Keys and Values do determine if a Reboot is pending.
 
.DESCRIPTION
 I found this Table on the Internet and decided to Write a Powershell Script to check if a Reboot is pending.
 Not all Keys are checked. But feel free to extend the Script.
 
 https://adamtheautomator.com/pending-reboot-registry-windows/
 KEY VALUE CONDITION
 HKLM:\SOFTWARE\Microsoft\Updates UpdateExeVolatile Value is anything other than 0
 HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager PendingFileRenameOperations value exists
 HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager PendingFileRenameOperations2 value exists
 HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired NA key exists
 HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending NA Any GUID subkeys exist
 HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting NA key exists
 HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce DVDRebootSignal value exists
 HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending NA key exists
 HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress NA key exists
 HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending NA key exists
 HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts NA key exists
 HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon JoinDomain value exists
 HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon AvoidSpnSet value exists
 HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName ComputerName Value ComputerName in HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName is different
 
.EXAMPLE
 ./Check-PendingReboot.ps1

#>

function Test-RegistryValue {
    param (
     [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Path,
     [parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]$Value
    )
    try {
     Get-ItemProperty -Path $Path -Name $Value -EA Stop
     return $true
    }  catch {
     return $false
    }
}

[bool]$PendingReboot = $false

#Check for Keys
If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") -eq $true)
{
    Write-Host "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    $PendingReboot = $true
}

If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting") -eq $true)
{
    Write-Host "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting"
    $PendingReboot = $true
}

If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") -eq $true)
{
    Write-Host "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    $PendingReboot = $true
}

If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -eq $true)
{
    Write-Host "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    $PendingReboot = $true
}

If ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts") -eq $true)
{
    Write-Host "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts"
    $PendingReboot = $true
}

#Check for Values
If ((Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing" -Value "RebootInProgress") -eq $true)
{
    Write-Host "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing > RebootInProgress"
    $PendingReboot = $true
}

If ((Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing" -Value "PackagesPending") -eq $true)
{
    Write-Host "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing > PackagesPending"
    $PendingReboot = $true
}

If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Value "PendingFileRenameOperations") -eq $true)
{
    Write-Host "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager > PendingFileRenameOperations"
    $PendingReboot = $true
}

If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Value "PendingFileRenameOperations2") -eq $true)
{
    Write-Host "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager > PendingFileRenameOperations2"
    $PendingReboot = $true
}

If ((Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Value "DVDRebootSignal") -eq $true)
{
    Write-Host "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce > DVDRebootSignal"
    $PendingReboot = $true
}

If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Value "JoinDomain") -eq $true)
{
    Write-Host "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon > JoinDomain"
    $PendingReboot = $true
}

If ((Test-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Value "AvoidSpnSet") -eq $true)
{
    Write-Host "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon > AvoidSpnSet"
    $PendingReboot = $true
}

Write-Host "Reboot pending: $PendingReboot"