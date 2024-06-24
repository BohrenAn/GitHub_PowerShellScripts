###############################################################################
# Check DomainController Ports
# 18.06.2024 V1.0 - Initial Version - Andres Bohren
# Requires ActiveDirectory PowerShell Module
#https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements
#Active Directory Web Services (ADWS)	TCP	9389
#Active Directory Management Gateway Service	TCP	9389
#Global Catalog	TCP	3269
#Global Catalog	TCP	3268
#Lightweight Directory Access Protocol (LDAP) Server	TCP	389
#LDAP Server	UDP	389
#LDAP SSL	TCP	636
#RPC	TCP	135
#SMB	TCP	445
###############################################################################
PARAM (
	[Parameter(Mandatory=$true)][String]$DomainController
	)

###############################################################################
Write-Host "This Computer:" -ForegroundColor Green

$HostName = [System.Net.Dns]::GetHostByName($env:computerName).HostName
Write-Host "Hostname: $HostName"

$NetAddress = Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4" -and $_.InterfaceIndex -gt "1" }
Write-Host "IPAddress: $($NetAddress.IPAddress)"

###############################################################################
Write-Host "Resolve DNS: $DomainController" -ForegroundColor Green
(Resolve-DnsName -Name $DomainController).IpAddress

###############################################################################
Write-Host "Traceroute" -ForegroundColor Green
$Result = Test-NetConnection -ComputerName $DomainController -TraceRoute
$Result.TraceRoute

###############################################################################
Write-Host "Checking TCP Ports..." -ForegroundColor Green
$ArrayPorts = @()
$ArrayPorts+= "135"
$ArrayPorts+= "389"
$ArrayPorts+= "636"
$ArrayPorts+= "445"
$ArrayPorts+= "3268"
$ArrayPorts+= "3269"
$ArrayPorts+= "9389"

$ArrayResult = @()
Foreach ($Port in $ArrayPorts)
{
	$Result = Test-NetConnection -ComputerName $DomainController -Port $Port
	
	# Create CustomObject
	$myObject = [PSCustomObject]@{
		ComputerName = $DomainController
		RemotePort = $Port
		TcpTestSucceeded = $Result.TcpTestSucceeded
	}
	
	$ArrayResult += $myObject
}

$ArrayResult | Format-Table ComputerName,RemotePort,TcpTestSucceeded

###############################################################################
Write-Host "Check AD Module - (Get 100 Users)..." -ForegroundColor Green
#Import ActiveDirectory Module
Import-Module ActiveDirectory

Try {
	$Users = Get-ADUser -Server $DomainController -ResultSetSize 100 -Filter *
	$Users.Count
} catch {
	Write-Host "An exception was caught: $($_.Exception.Message)" -ForegroundColor Yellow
}

#Test Ports with System.Net.Sockets.TcpClient (Allows to set Timeout)
#$tcpClient = New-Object System.Net.Sockets.TcpClient
#$portOpened = $tcpClient.ConnectAsync($DomainController, "389").Wait(1000)