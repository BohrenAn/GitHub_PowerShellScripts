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
Write-Host "Import DLLPickle Module"
Import-Module DLLPickle
$Null = Import-DPLibrary

Write-Host "Connect to Exchange Online"
Connect-ExchangeOnline -Showbanner:$false

Write-Host "Connect to Microsoft Graph"
Connect-MgGraph -Scopes Application.Read.All -NoWelcome

$FileName = Get-FileName -initialDirectory $PSScriptRoot
If ($Null -eq $FileName)
{
    Write-Host "No File selected. Exiting Script" -ForegroundColor Red
    Exit
}

$CSV = Import-Csv -Path $FileName -Delimiter ";" -Encoding utf8

$INT = 0
Forach ($Line in $CSV)
{
    $INT = $INT + 1
    $AppID = $Line.AppID
    $AppPermission = $Line.AppPermission
    $GroupObjectID = $Line.GroupObjectID

    Write-Host "AppID: $AppID [$INT]" -ForegroundColor Green
    Write-Host "AppPermission: $AppPermission" -ForegroundColor Green
    Write-Host "GroupObjectID: $GroupObjectID" -ForegroundColor Green

    .\04_CreateEXORBACApplication.ps1 -AppID $AppID -AppPermission $AppPermission -GroupObjectID $GroupObjectID
}



###############################################################################
# Get AzureAD Application with Microsoft.Graph PowerShell
###############################################################################
Connect-MgGraph -Scopes 'Application.Read.All'
$ServicePrincipalDetails = Get-MgServicePrincipal -Filter "DisplayName eq 'Demo-EXO-RBAC'"
$ServicePrincipalDetails

###############################################################################
# Create Exchange Service Principal
###############################################################################
Connect-ExchangeOnline
New-ServicePrincipal -AppId $ServicePrincipalDetails.AppId -ServiceId $ServicePrincipalDetails.Id -DisplayName "EXO Serviceprincipal $($ServicePrincipalDetails.Displayname)"
Get-ServicePrincipal | where {$_.AppId -eq "cd32481c-6da8-47a1-b55b-742d2c3af888"}

###############################################################################
#Get-ManagementRole
###############################################################################
Get-ManagementRole | where {$_.Name -like "Application*"}