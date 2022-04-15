#Set Exchange Services to Auto and Start them
Get-Service -Name MSE* | Set-Service -StartupType Automatic
Set-Service -Name MSExchangeImap4 -StartupType Disabled
Set-Service -Name MSExchangeIMAP4BE -StartupType Disabled
Set-Service -Name MSExchangePop3 -StartupType Disabled
Set-Service -Name MSExchangePOP3BE -StartupType Disabled
Write-Host "Starting Services..."
Get-Service -Name MSE* | where {$_.StartType -ne "Disabled"} | Start-Service

Write-Host "Starting Services..."
Get-Service -Name MSE* | where {$_.StartType -ne "Disabled"} | Start-Service

<#


do{
Write-Host "Enable MSE* Services" -ForegroundColor Green
Get-Service -Name MSE* | Set-Service -StartupType Automatic
Set-Service -Name MSExchangeImap4 -StartupType Disabled
Set-Service -Name MSExchangeIMAP4BE -StartupType Disabled
Set-Service -Name MSExchangePop3 -StartupType Disabled
Set-Service -Name MSExchangePOP3BE -StartupType Disabled

Write-Host "Press CTRL + C for Stopping"
Write-Host "Sleep 15 Sec"
Start-Sleep -Seconds 15

} while (1 -eq 1)

#>