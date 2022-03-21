###############################################################################
# If you have multiple Versions of MicrosoftGraph PowerShell Module installed
# This Scripts uninstalls the Old versions and installs only the Current Version
# 20.03.2022 V0.1 - Initial Draft - Andres Bohren
###############################################################################
#Script needs to Run as Administrator to uninstall/install PowerShell Modules
#Requires -RunAsAdministrator

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
$Versions = Get-Module $ModuleName -ListAvailable
Foreach ($Version in $Versions)
{
    $ModuleVersion = $Version.Version
    Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
    Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
}
#Finally install the newest Version
Install-Module Microsoft.Graph