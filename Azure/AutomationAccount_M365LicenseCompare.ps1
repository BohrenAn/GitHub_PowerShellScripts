###############################################################################
# M365 License Compare
# Compares the Licenses in a M365 Tenant with an exported Object stored on Azure FileShare
# 03.12.2023 - Initial Version - Andres Bohren https://blog.icewolf.ch
###############################################################################
# Required Infrastructure
# - Azure Automation Account with System Assigned Managed Identity
# - Azure Storageaccount with FileShare
# Required Permissions
# - Azure Automation Account Managed Identity must be member of "License Administrator" Role
# - EntraID Application with Application Mail.Send Permissions (for Sending Mail via Microsoft Graph)
# - App can be limited with ApplicationAccessPolicies to specific Mailboxes 
#   https://blog.icewolf.ch/archive/2021/02/06/limit-microsoft-graph-access-to-specific-exchange-mailboxes/
# Required Modules:
# - Az.Accounts
# - Az.Storage
# - Microsoft.Graph.Authentication
# - Microsoft.Graph.Identity.DirectoryManagement
# Required Automation Account Variables
# - StorageAccountName
# - StorageAccountKey
# - LicenseCompareShare (csv)
# - LicenseCompareFile (ArraySKUS.xml)
# - DelegatedMailAppID (AppID)
# - TenantGuId (TenantID GUID)
# Automation Account Certificate
# - AutomationCertificate for Authentication to Entra AppID for Sending Mail


###############################################################################
# This Function Sends the Admin Mail
# https://blog.icewolf.ch/archive/2021/07/07/graph-api-send-mail-with-powershell/
# MSAL.PS has been replaced by PSMSALNet
# https://blog.icewolf.ch/archive/2023/10/16/testing-psmsalnet-because-msal-ps-has-been-archived/
###############################################################################
Function Send-AdminMail
{

	param (
		[Parameter(Mandatory = $true)][string]$Subject,
		[parameter(mandatory = $true)][string]$MessageBody,
        [parameter(mandatory = $true)][string]$Recipient,
        [parameter(mandatory = $true)][string]$Sender
	)

    ### Getting Variables ###
    #App
    $AppID = Get-AutomationVariable -Name "DelegatedMailAppID"
    Write-Output "AppID --> $AppID"

    #TenantID
    $TenantID = Get-AutomationVariable -Name "TenantGuId"
    Write-Output "TenantId --> $TenantID"

    #Certificate
    $Certificate = Get-AutomationCertificate -name "O365Powershell3"
    $CertificateThumbprint = $Certificate.ThumbPrint
    Write-Output "CertificateThumbprint --> $CertificateThumbprint"

    ### Authenticate with Certificate ### 
    Import-Module PSMSALNet
    $HashArguments = @{
    ClientId = $AppID
    ClientCertificate = $Certificate
    TenantId = $TenantId
    Resource = "GraphAPI"
    }
    $Token = Get-EntraToken -ClientCredentialFlowWithCertificate @HashArguments
    $AccessToken = $Token.AccessToken

    #DEBUG
    #Write-Output "AccessToken $AccessToken"

### Send Email ###
$URI = "https://graph.microsoft.com/v1.0/users/$Sender/sendMail"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$Body = @"
{
    "message": {
        "subject": "$Subject",
        "body": {
            "contentType": "HTML",
            "content": '$MessageBody'
        },
        "toRecipients": [
            {
                "emailAddress": {
                    "address": "$Recipient"
                }
            }
        ]
    }
}
"@

    #Invoke-RestMethod To send the Mail
    $Result = Invoke-RestMethod -Method "POST" -Uri $uri -Body $Body -Headers $Headers -ContentType $ContentType
}


###############################################################################
# Main Script
###############################################################################
Write-Output "Getting Automation Account Variables"
$StorageAccountName = Get-AutomationVariable -Name "StorageAccountName"
Write-Output "StorageAccountName --> $StorageAccountName"

$StorageAccountKey = Get-AutomationVariable -Name "StorageAccountKey"
$LicenseCompareShare = Get-AutomationVariable -Name "LicenseCompareShare"
Write-Output "LicenseCompareShare --> $LicenseCompareShare"

$LicenseCompareFile = Get-AutomationVariable -Name "LicenseCompareFile"
Write-Output "LicenseCompareFile --> $LicenseCompareFile"

#Import AZ Modules
Write-Output "Import-Module Az.Accounts"
Import-Module Az.Accounts
Write-Output "Import-Module Az.Storage"
Import-Module Az.Storage

#Define the path, where the file gets saved. It just takes the location of the script.
#$path = Split-Path -parent $PSCommandPath
$path = $env:temp 

#Download XML from Azure Storage
Write-Output "Download $LicenseCompareFile from AzureStorage"
$DestinationFile = $path + "\$LicenseCompareFile"
Write-Output "DEBUG: DestinationFile: $DestinationFile "
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey 
Get-AzStorageFileContent -ShareName $LicenseCompareShare -Path "/$LicenseCompareFile" -Context $StorageContext -Destination $DestinationFile -Erroraction SilentlyContinue


#Connect-MgGraph
Write-Output "Connect-MgGraph"
Connect-MgGraph -NoWelcome -ManagedIdentity
#-Scopes User.ReadWrite.All, Directory.ReadWrite.All 


###############################################################################
# SKU's an License with MgGraph and PSCustomObject
# https://blog.icewolf.ch/archive/2021/11/29/hinzufugen-und-entfernen-von-m365-lizenzen-mit-microsoft-graph-powershell/
###############################################################################
#Array with all needed Properties using PSCustomObject
Write-Output "Create PSCustomObject"
$ArraySKUS = @()
$SKUS = Get-MgSubscribedSku
Foreach ($SKU in $SKUS)
{
    #$ArraySKU = @()
    $AppliesTo = $SKU.AppliesTo
    $CapabilityStatus = $SKU.CapabilityStatus
    $SkuId = $SKU.SkuId
    $SkuPartNumber = $SKU.SkuPartNumber
    Write-Output "Working on SKUPartNumber: $SkuPartNumber"
	[array]$ServicePlans = $SKU.ServicePlans.ServicePlanName
    $ConsumedUnits = $SKU.ConsumedUnits
    $Enabled = $SKU.PrepaidUnits.Enabled
    $Suspended = $SKU.PrepaidUnits.Suspended
    $Warning = $SKU.PrepaidUnits.Warning
    $SKUObject = [PSCustomObject]@{
        AppliesTo             = $AppliesTo
        CapabilityStatus     = $CapabilityStatus
        SkuId                = $SkuId
        SkuPartNumber        = $SkuPartNumber
		ServicePlans		 = $ServicePlans
        ConsumedUnits        = $ConsumedUnits
        Enabled                = $Enabled
        Suspended            = $Suspended
        Warning                = $Warning
    }
    $ArraySKUS += $SKUObject
}
#$ArraySKUS | FT

#Import Object
If ((Test-Path $DestinationFile) -eq $False)
{
    Write-Output "Downloaded File for Compare NOT found"
    $MessageBody = "Initial Run of License Compare"
} else {

    Write-Output "Import saved Object"
    $SavedObject = Import-Clixml -Path $DestinationFile

    #Compare Objects
    Write-Output "Compare Objects"
    $Output = @()
    $INT = 0
    Foreach ($Line in $ArraySKUs)
    {
        $SkuPartNumber = $Line.SkuPartNumber
        Write-Output "Working on: $SkuPartNumber" #-ForegroundColor Green
        $DifferenceObject = $SavedObject[$INT].ServicePlans
        $CompareResult = Compare-Object -ReferenceObject $Line.ServicePlans -DifferenceObject $DifferenceObject #-PassThru
        If ($CompareResult -ne $Null)
        {
            #$CompareResult
            $Diff = $CompareResult
            Write-Output "Diffrence found: $($Diff.InputObject) $($Diff.SideIndicator)" #-ForegroundColor Yellow
            $OutputObject = [PSCustomObject]@{
                SkuPartNumber = $SkuPartNumber 
                ServicePlan =  $($Diff.InputObject)
                SideIndicator = $($Diff.SideIndicator)
            }
            $Output += $OutputObject 
        }

        $INT = $Int + 1
    }

    If ($Output.Count -ne 0)
    {
        [string]$MessageBody = $Output | ConvertTo-Html
    } else {
        $MessageBody = "No Changes found"
    }

}

#Send Admin Mail
Write-Output "Sending Admin Mail"
Send-AdminMail -Subject "Compare M365 Licenses" -MessageBody $MessageBody -Recipient "a.bohren@icewolf.ch" -Sender "postmaster@icewolf.ch"

#Export Object
Write-Output "Export PSCustomObject"
$ArraySKUS | Export-Clixml $DestinationFile

#Upload XML To Azure Storage
Write-Output "Upload $LicenseCompareFile to AzureStorage"
Set-AzStorageFileContent -ShareName $LicenseCompareShare -Source $DestinationFile -Path "/$LicenseCompareFile" -Context $StorageContext -Force -Erroraction SilentlyContinue

#Disconnect-MgGraph
Write-Output "Disconnect-MgGraph"
Disconnect-MgGraph | Out-Null