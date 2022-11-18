###############################################################################
# Cleanup-AzModules.ps1
# If you have multiple Versions of AZ.* PowerShell Module installed
# This Scripts uninstalls the Old versions and installs only the Current Version
# 25.04.2022 V0.1 - Initial Draft - Andres Bohren
# 07.06.2022 V0.2 - Also uninstall AZ Module - Andres Bohren
# 03.08.2022 V0.3 - Changed some commands to Get-InstalledModule
# 18.11.2022 V0.4 - Addet Process check
###############################################################################
#Script needs to Run as Administrator to uninstall/install PowerShell Modules
#Requires -RunAsAdministrator

#Check if VSCode or PowerShell is running
[array]$process = Get-Process | Where-Object {$_.ProcessName -eq "powershell" -or $_.ProcessName -eq "pwsh" -or $_.ProcessName -eq "code"}
#$process = Get-Process -Name code -ErrorAction SilentlyContinue
If ($process.Count -gt 1)
{
	Write-Host "PowerShell or Visual Studio Code running? Please close it, otherwise the Modules sometimes can't be updated..." -ForegroundColor Red
	
	#Press any key to continue
	Write-Host 'Press any key to continue...';
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
	Write-Host "Checking Modules..."
}

#Remove loaded az.* Modules
Remove-Module az.*

#Iterate through Modules and uninstall
$Modules = Get-Module AZ.* -ListAvailable | Where-Object {$_.Name -ne "Az.Accounts"} | Select-Object Name -Unique
Foreach ($Module in $Modules)
{
    $ModuleName = $Module.Name
    $Versions = Get-InstalledModule $ModuleName -AllVersions
    Foreach ($Version in $Versions)
    {
        $ModuleVersion = $Version.Version
        Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
        Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
    }
}
#Uninstall Az.Accounts
$ModuleName = "Az.Accounts"
$Versions = Get-InstalledModule $ModuleName -AllVersions
Foreach ($Version in $Versions)
{
    $ModuleVersion = $Version.Version
    Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
    Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
}
#Uninstall Az
$ModuleName = "Az"
$Versions = Get-InstalledModule $ModuleName -AllVersions
Foreach ($Version in $Versions)
{
    $ModuleVersion = $Version.Version
    Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
    Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion -Force
}

#Install newest Module
Write-Host "Install newest AZ Module"
Install-Module AZ
Write-Host "Cleanup finished"