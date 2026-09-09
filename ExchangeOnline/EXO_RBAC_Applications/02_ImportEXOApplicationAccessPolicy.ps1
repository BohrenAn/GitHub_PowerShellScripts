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

# Application Permissions in Exchange Online
# Get-ManagementRole | where {$_.Name -match "Application "}
$ExchangePermissions = [System.Collections.Generic.List[string]]::new()
$ExchangePermissions.Add("MailboxItem.Export")
$ExchangePermissions.Add("MailboxItem.ReadWrite")
$ExchangePermissions.Add("Mail-Advanced.ReadWrite.All")
$ExchangePermissions.Add("Mail.Read")
$ExchangePermissions.Add("Mail.ReadBasic")
$ExchangePermissions.Add("Mail.ReadWrite")
$ExchangePermissions.Add("Mail.Send")
$ExchangePermissions.Add("MailboxSettings.Read")
$ExchangePermissions.Add("MailboxSettings.ReadWrite")
$ExchangePermissions.Add("Calendars.Read")
$ExchangePermissions.Add("Calendars.ReadWrite")
$ExchangePermissions.Add("Contacts.Read")
$ExchangePermissions.Add("Contacts.ReadWrite")
$ExchangePermissions.Add("Mail Full Access")
$ExchangePermissions.Add("Exchange Full Access")
$ExchangePermissions.Add("EWS.AccessAsApp")
$ExchangePermissions.Add("SMTP.SendAsApp")
$ExchangePermissions.Add("MailboxConfigItem.Read")
$ExchangePermissions.Add("MailboxConfigItem.ReadWrite")
$ExchangePermissions.Add("MailTips.ReadBasic.All")
$ExchangePermissions.Add("MailboxFolder.Read")
$ExchangePermissions.Add("MailboxFolder.ReadWrite")
$ExchangePermissions.Add("MailboxItem.Read")
$ExchangePermissions.Add("ApplicationMailboxItem.ImportExport")


# Loop through the CSV file and process each line
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

    # Only if its an EXO App Permission
    If ($ExchangePermissions -match $AppPermission)
    {
        # Create the Exchange Online RBAC Application for the matching permission
        Write-Host "Create Exchange Online RBAC Application"
        .\04_CreateEXORBACApplication.ps1 -AppID $AppID -AppPermission $AppPermission -GroupObjectID $GroupObjectID -Verbose
    }

    
}
