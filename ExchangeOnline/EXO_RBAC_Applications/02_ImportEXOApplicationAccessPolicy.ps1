###############################################################################
# Import Exchange ApplicationAccessPolicy
# Create Exchange Exchange RBAC for Applications from CSV file
# V0.1 xx.xx.2026 - Initial Version - Andres Bohren
###############################################################################
# Reqired Modules:
# - ExchangeOnlineManagement
# - Microsoft.Graph
# Required Permissions:
# - Exchange Administrator (Exchange Online)
# - Application.Read.All (Microsoft Graph)
###############################################################################
# Install-PSResource -Name DllPickle -Scope CurrentUser

###############################################################################
# Get Filename
###############################################################################
Function Get-FileName
{
    PARAM (
        [string]$initialDirectory
    )

    [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.ShowHelp = $true
    $OpenFileDialog.filter = "CSV Files (*.csv)| *.csv|TXT Files (*.txt)|*.txt"
    #$OpenFileDialog.filter = "TXT Files (*.txt)|*.txt"
    $show = $OpenFileDialog.ShowDialog()
    If ($Show -eq "OK")
    {
        Return $OpenFileDialog.FileName
    }
}

###############################################################################
# Main Script starts here
###############################################################################
<#
Write-Host "Import DLLPickle Module"
Import-Module DLLPickle
$Null = Import-DPLibrary

Write-Host "Connect to Microsoft Graph"
Connect-MgGraph -Scopes Application.Read.All -NoWelcome

Write-Host "Connect to Exchange Online"
Connect-ExchangeOnline -Showbanner:$false
#>

$FileName = Get-FileName -initialDirectory $PSScriptRoot
If ($Null -eq $FileName)
{
    Write-Host "No File selected. Exiting Script" -ForegroundColor Red
    Exit
}

$CSV = Import-Csv -Path $FileName -Delimiter ";" -Encoding UTF8

$INT = 0
Foreach ($Line in $CSV)
{
    $INT = $INT + 1
    $AppID = $Line.AppID
    $AppPermission = $Line.AppPermission
    $GroupObjectID = $Line.GroupObjectID

    Write-Host "AppID: $AppID [$INT]" -ForegroundColor Green
    Write-Host "AppPermission: $AppPermission" -ForegroundColor Green
    Write-Host "GroupObjectID: $GroupObjectID" -ForegroundColor Green

    .\04_CreateEXORBACApplication.ps1 -AppID $AppID -AppPermission $AppPermission -GroupObjectID $GroupObjectID -Verbose
}
