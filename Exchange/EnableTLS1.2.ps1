###############################################################################
# Enable TLS 1.2
# 23.05.2024 - Andres Bohren
###############################################################################
<#
Transport Layer Security (TLS) best practices with the .NET Framework
https://learn.microsoft.com/en-us/dotnet/framework/network-programming/tls

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

[HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server]
"Enabled"==dword:00000001
"DisabledByDefault"=dword:00000000

[HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client]
"Enabled"==dword:00000001
"DisabledByDefault"=dword:00000000
#>

$RegKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727"
If ((Test-Path -Path $RegKey) -eq $false)
{
	Write-Host "Create Registry Key: $RegKey" -ForegroundColor Yellow
	New-Item -Path $RegKey -Force | Out-Null
}

$Property = "SystemDefaultTlsVersions"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "SchUseStrongCrypto"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$RegKey = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727"
If ((Test-Path -Path $RegKey) -eq $false)
{
	Write-Host "Create Registry Key: $RegKey" -ForegroundColor Yellow
	New-Item -Path $RegKey -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "SystemDefaultTlsVersions"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "SchUseStrongCrypto"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$RegKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
If ((Test-Path -Path $RegKey) -eq $false)
{
	Write-Host "Create Registry Key: $RegKey" -ForegroundColor Yellow
	New-Item -Path $RegKey -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "SystemDefaultTlsVersions"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "SchUseStrongCrypto"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}


$RegKey = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
If ((Test-Path -Path $RegKey) -eq $false)
{
	Write-Host "Create Registry Key: $RegKey" -ForegroundColor Yellow
	New-Item -Path $RegKey -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "SystemDefaultTlsVersions"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "SchUseStrongCrypto"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}


$RegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"
If ((Test-Path -Path $RegKey) -eq $false)
{
	Write-Host "Create Registry Key: $RegKey" -ForegroundColor Yellow
	New-Item -Path $RegKey -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "Enabled"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "DisabledByDefault"
$PropertyValue = "0"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}


$RegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"
If ((Test-Path -Path $RegKey) -eq $false)
{
	Write-Host "Create Registry Key: $RegKey" -ForegroundColor Yellow
	New-Item -Path $RegKey -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "Enabled"
$PropertyValue = "1"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

$Property = "DisabledByDefault"
$PropertyValue = "0"
$Item = Get-ItemProperty -Path $RegKey -Name $Property -ErrorAction SilentlyContinue
If ($Item.$Property -ne $PropertyValue)
{
    Write-Host "Create Registry Value: $RegKey $Property $PropertyValue" -ForegroundColor Yellow
	New-ItemProperty -path $RegKey -Name $Property -value $PropertyValue -PropertyType 'DWord' -Force | Out-Null
} else {
	Write-Host "Registry Value already exists: $RegKey $Property $PropertyValue" -ForegroundColor Green
}

Write-Host 'TLS 1.2 has been enabled.'