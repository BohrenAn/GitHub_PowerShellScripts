###############################################################################
# Delete Stale Devices with Microsoft.Graph PowerShell
# 08.03.2023 V0.1 - Initial Version - Andres Bohren
# https://blog.icewolf.ch/archive/2023/02/08/delete-stale-devices-in-azuread-with-microsoft-graph-powershell/
###############################################################################

Connect-MgGraph -Scopes Directory.ReadWrite.All, Directory.AccessAsUser.All
$Devices = Get-MgDevice

#$Devices | Where-Object {$_.ApproximateLastSignInDateTime -lt (Get-Date).AddMonths(-6)}
$Devices | Where-Object {$_.ApproximateLastSignInDateTime -lt (Get-Date).AddMonths(-6)}  | Format-Table DisplayName,AccountEnabled,OperatingSystem,OperatingSystemVersion,ProfileType,IsManaged,IsCompliant,OnPremisesSyncEnabled,ApproximateLastSignInDateTime

$StaleDevices = $Devices | Where-Object {$_.ApproximateLastSignInDateTime -lt (Get-Date).AddMonths(-6)}
Foreach ($StaleDevice in $StaleDevices)
{
    Write-Host "DisplayName: $($StaleDevice.DisplayName) ApproximateLastSignInDateTime: $($StaleDevice.ApproximateLastSignInDateTime)"
    $DeviceId = $StaleDevice.Id
    Write-Host "Delete Id: $DeviceId" -ForegroundColor Yellow
    Remove-MgDevice -DeviceId $DeviceId
}