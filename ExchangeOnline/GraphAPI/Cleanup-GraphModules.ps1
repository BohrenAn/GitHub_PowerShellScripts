###############################################################################
# Cleanup-GraphModules.ps1
# If you have multiple Versions of MicrosoftGraph PowerShell Module installed
# This Scripts uninstalls the Old versions and installs only the Current Version
# 20.03.2022 V0.1 - Initial Draft - Andres Bohren
# 05.04.2022 V0.2 - Added Remove-Module / some Write-Host - Andres Bohren
# 05.08.2022 V0.3 - Changed some commands to Get-InstalledModule
###############################################################################
#Script needs to Run as Administrator to uninstall/install PowerShell Modules
#Requires -RunAsAdministrator

#Remove loaded Microsoft.Graph* Modules
Remove-Module Microsoft.Graph*

#Get Microsoft.Graph Modules except Microsoft.Graph.Authentication because the other Modules have dependencys
$Modules = Get-Module Microsoft.Graph* -ListAvailable | Where-Object {$_.Name -ne "Microsoft.Graph.Authentication"} | Select-Object Name -Unique
Foreach ($Module in $Modules)
{
    $ModuleName = $Module.Name
    #Get Installed Versions of that specific Module
    $Versions = Get-Module $ModuleName -ListAvailable
    Foreach ($Version in $Versions)
    {
        #Uninstall Module
        $ModuleVersion = $Version.Version
        Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
        Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
    }
}
#Uninstall Microsoft.Graph.Authentication
$ModuleName = "Microsoft.Graph.Authentication"
$Versions = Get-InstalledModule $ModuleName -AllVersions
Foreach ($Version in $Versions)
{
    $ModuleVersion = $Version.Version
    Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
    Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
}

#Uninstall Microsoft.Graph
$ModuleName = "Microsoft.Graph"
$Versions = Get-InstalledModule $ModuleName -AllVersions
Foreach ($Version in $Versions)
{
    $ModuleVersion = $Version.Version
    Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
    Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
}

#Finally install the newest Version
Write-Host "Install newest Microsoft.Graph Module"
Install-Module Microsoft.Graph
Write-Host "Cleanup finished"