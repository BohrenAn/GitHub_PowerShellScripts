###############################################################################
# Azure Automation Account with AZ PowerShell
# 19.08.2025 - Initial Version - Andres Bohren
###############################################################################

###############################################################################
# # Install AZ PowerShell Module
###############################################################################

Find-PSResource -Name Az 
Install-PSResource -Name AZ -Scope CurrentUser

#Show Version of AZ.Automation Module
Find-PSResource -Name Az.Automation | Format-List

# Show all Commands in Az.Automation Module
(Get-Command -Module Az.Automation).count
Get-Command -Module Az.Automation

###############################################################################
# Connect to Azure with AZ PowerShell
###############################################################################
Connect-AzAccount -Tenant "icewolfch.onmicrosoft.com"
Select-AzSubscription "42ecead4-eae9-4456-997c-1580c58b54ba"
Get-AzAutomationAccount

###############################################################################
# Create Automation Account - with System Managed Identity
###############################################################################
$AutomationAccountName = "AutomationDemoPS"
$Location = "westeurope"
$RG = "RG_Demo"
New-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $RG -Location $Location -AssignSystemIdentity

###############################################################################
# Get Runtime Environments
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/runtime-environments?view=rest-automation-2024-10-23
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_Demo"
$AutomationAccountName = "AutomationDemoPS"

#Invoke AzRestMethod
$Result = Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments?api-version=2024-10-23" 

#List Names Convert frm JSON and select Name
($result.Content | convertFrom-Json).Value | Select-Object Name

###############################################################################
# Create Runtime Environment
###############################################################################
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RuntimeEnvironment = "PowerShell-74"

$body = @"
{
    "properties": {
        "runtime": {
        "language": "PowerShell",
        "version": "7.4"
    },
        "defaultPackages": {
            "Az": "12.3.0",
            "Azure CLI": "2.64.0"
        }
    },
    "location": "westeurope"
}
"@

Invoke-AzRestMethod -Method "PUT" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/?api-version=2024-10-23" -Payload $Body

###############################################################################
# Update Default Packages
###############################################################################
#Note: Only old Version available of AZ and Azure CLI
#Current Versions: AZ 14.3.0 / AZ CLI 2.75.0
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RuntimeEnvironment = "PowerShell-74"

$body = @"
{
    "properties": {
        "DefaultPackages": {
            "Az": "12.3.0",
            "Azure CLI": "2.64.0"
        }
    }
}
"@

Invoke-AzRestMethod -Method "Patch" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/?api-version=2024-10-23" -Payload $Body

###############################################################################
# Add Powershell Package
###############################################################################
#https://learn.microsoft.com/de-de/powershell/module/az.automation/new-azautomationmodule?view=azps-14.3.0
#New-AzAutomationModule -RuntimeVersion [5.1,7.2]
#https://learn.microsoft.com/en-us/rest/api/automation/package/create-or-update?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RuntimeEnvironment = "PowerShell-74"
$Module = "Microsoft.Graph.Authentication"
$Version = "2.29.0"
$URI = "https://www.powershellgallery.com/api/v2/package/$Module/$Version"

$body = @"
{
"properties": {
    "contentLink": {
    "uri": "$URI"
    }
}
}
"@

Invoke-AzRestMethod -Method "PUT" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/packages/$Module/?api-version=2024-10-23" -Payload $Body

###############################################################################
# Get PowerShell Packages
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/package/get?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RuntimeEnvironment = "PowerShell-74"

Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/packages/?api-version=2024-10-23"

###############################################################################
# Update Powershell Package
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/package/create-or-update?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RuntimeEnvironment = "PowerShell-74"
$Module = "Microsoft.Graph.Authentication"
$Version = "2.29.1"
$URI = "https://www.powershellgallery.com/api/v2/package/$Module/$Version"

$body = @"
{
"properties": {
    "contentLink": {
    "uri": "$URI"
    }
}
}
"@

Invoke-AzRestMethod -Method "PUT" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/packages/$Module/?api-version=2024-10-23" -Payload $Body

###############################################################################
# Remove Powershell Package
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/package/delete?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RuntimeEnvironment = "PowerShell-74"
$Module = "Microsoft.Graph.Authentication"

Invoke-AzRestMethod -Method "DELETE" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runtimeEnvironments/$RuntimeEnvironment/packages/$Module/?api-version=2024-10-23"

```pwsh
###############################################################################
# Create Runbook Draft
###############################################################################
#New-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name $RunbookName -ResourceGroupName $ResourceGroupName -Type "PowerShell"
# ->> Does not Support Runtime Evironment
#https://learn.microsoft.com/en-us/rest/api/automation/runbook/create-or-update?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$Location = "westeurope"
$RuntimeEnvironment = "PowerShell-74"
$RunbookName = "Demo_Runbook"

$Body = @"
{
    "name": "$RunbookName",
    "location": "$Location",
    "properties": {
        "runbookType": "PowerShell",
        "runtimeEnvironment": "$RuntimeEnvironment",
        "logProgress": false,
        "logVerbose": false,
        "draft": {}
    },
    "tags": null
}
"@

Invoke-AzRestMethod -Method "PUT" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runbooks/$RunbookName/?api-version=2024-10-23" -Payload $Body

###############################################################################
# Get Runbook
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/runbook/get?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$Location = "West Europe"
$RuntimeEnvironment = "PowerShell-74"
$RunbookName = "Demo_Runbook"

Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runbooks/$RunbookName/?api-version=2024-10-23"

###############################################################################
# Update Runbook Draft Content
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/runbook-draft/replace-content?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$Location = "westeurope"
$RuntimeEnvironment = "PowerShell-74"
$RunbookName = "Demo_Runbook"

$Body = @'
Write-Output "Demo Runbook $(Get-Date -f 'yyyy-MM-dd')"
'@

Invoke-AzRestMethod -Method "PUT" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runbooks/$RunbookName/draft/content?api-version=2024-10-23" -Payload $Body

###############################################################################
# Get Runbook Draft Content
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/runbook-draft/get-content?view=rest-automation-2024-10-23&tabs=HTTP
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$Location = "westeurope"
$RunbookName = "Demo_Runbook"

$Result = Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runbooks/$RunbookName/draft/content/?api-version=2024-10-23"
$Result.Content

###############################################################################
# Publish-AzAutomationRunbook
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/publish-azautomationrunbook?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RunbookName = "DemoPS1"

Publish-AzAutomationRunbook -Name $RunbookName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName

###############################################################################
# Publish Runbook
###############################################################################
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$Location = "westeurope"
$RuntimeEnvironment = "PowerShell-74"
$RunbookName = "Demo_Runbook"

Invoke-AzRestMethod -Method "POST" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runbooks/$RunbookName/publish?api-version=2024-10-23"

###############################################################################
# Start Runbook
###############################################################################
#https://learn.microsoft.com/de-de/powershell/module/az.automation/start-azautomationrunbook?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RunbookName = "Demo_Runbook"

Start-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName 

###############################################################################
# Set Source Control
###############################################################################
# https://learn.microsoft.com/en-us/rest/api/automation/source-control/create-or-update?view=rest-automation-2024-10-23&tabs=HTTP
# Azure DevOps
# - Personal Access Token
# - Permission: Code: Read / Write
# Azure
# - Managed Identity requires "Automation Contributor" on Automation Account

$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$SourceControl = "AzureDevOps"
$PAT = Get-Content -Path "C:\Temp\DevOpsPAT.txt"

$Body = @"
{
"properties": {
    "repoUrl": "https://dev.azure.com/abohren/_git/AzureAutomation",
    "branch": "main",
    "folderPath": "/AutomationDemoPS",
    "autoSync": true,
    "publishRunbook": true,
    "sourceType": "VsoGit",
    "securityToken": {
        "accessToken": "$PAT",
        "tokenType": "PersonalAccessToken"
    },
    "description": "my description"
}
}
"@

Invoke-AzRestMethod -Method "PUT" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/sourceControls/$SourceControl/?api-version=2024-10-23" -Payload $Body

###############################################################################
# Get Source Control
###############################################################################
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$SourceControl = "AzureDevOps"

Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/sourceControls/$SourceControl/?api-version=2024-10-23"

###############################################################################
# Delete the Source Control
###############################################################################
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$SourceControl = "AzureDevOps"

Invoke-AzRestMethod -Method "DELETE" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/sourceControls/$SourceControl/?api-version=2024-10-23"

###############################################################################
# Update Runbook to another Runtime Environment
###############################################################################
#https://learn.microsoft.com/en-us/rest/api/automation/runbook/update?view=rest-automation-2024-10-23&tabs=HTTP
#Write-Output "Demo PS5.1"
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$RuntimeEnvironment = "PowerShell-74"
$Runbook = "DemoPS5"

$body = @"
{
    "properties": {
        "runtimeEnvironment": "$RuntimeEnvironment",
        "runbookType": "PowerShell"
    }
}
"@

Invoke-AzRestMethod -Method "PATCH" -Path "/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.Automation/automationAccounts/$AutomationAccountName/runbooks/$Runbook/?api-version=2024-10-23" -Payload $Body

###############################################################################
# Create Self Signed Certificate
###############################################################################
$Subject = "DemoCert"
$NotAfter = (Get-Date).AddMonths(+24)
$Cert = New-SelfSignedCertificate -Subject $Subject -CertStoreLocation "Cert:\CurrentUser\My" -KeySpec Signature -NotAfter $Notafter -KeyExportPolicy Exportable
$ThumbPrint = $Cert.ThumbPrint

#View Certificates in the Current User Certificate Store
Get-ChildItem -Path cert:\CurrentUser\my\$ThumbPrint | Format-Table

###############################################################################
# Export PFX
###############################################################################
$Cert = "Cert:\CurrentUser\My\$ThumbPrint"
$pfxPath = "C:\Temp\DemoCert.pfx"
$pfxPassword = ConvertTo-SecureString -String "YourStrongPassword" -Force -AsPlainText

# Export the certificate
Export-PfxCertificate -Cert $Cert -FilePath $pfxPath -Password $pfxPassword

###############################################################################
# New Automation Certificate
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/new-azautomationcertificate?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$CertificateName = "DemoCert"
$pfxPath = "C:\Temp\DemoCert.pfx"
$pfxPassword = ConvertTo-SecureString -String "YourStrongPassword" -Force -AsPlainText

New-AzAutomationCertificate -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $CertificateName -Path $pfxPath -Password $pfxPassword

###############################################################################
# Get Automation Certificate
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/get-azautomationcertificate?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$CertificateName = "DemoCert"
Get-AzAutomationCertificate -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $CertificateName

###############################################################################
# New Automation Variable
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/new-azautomationvariable?view=azps-14.3.0
<#
String
Boolean
DateTime
Integer
Not specified
Object
#>
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$VariableName = "DemoVar"
$VariableValue = "MyValue"

New-AzAutomationVariable -ResourceGroupName $ResourceGroupName  -AutomationAccountName $AutomationAccountName -Name $VariableName -Value $VariableValue -Encrypted $false

###############################################################################
# Get Automation Variable
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/get-azautomationvariable?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$VariableName = "DemoVar"

$Variable = Get-AzAutomationVariable -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $VariableName
$Variable.Value

###############################################################################
# New-AzAutomationSchedule
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/new-azautomationschedule?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"

#OneTime
$TimeZone = "Europe/Paris"
$ScheduleName = "OneTime"
$StartTime = (Get-Date "20:00").AddDays(+1) #Must be 5 Min in Future
New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $StartTime -OneTime -TimeZone $TimeZone

#Daily
$ScheduleName = "Daily"
$StartTime = (Get-Date "20:15").AddDays(+1) #Must be 5 Min in Future
New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $StartTime -DayInterval 1

#Weekly
$ScheduleName = "Weekly"
$StartTime = (Get-Date "20:30").AddDays(+1) #Must be 5 Min in Future
#[System.DayOfWeek[]]$WeekDays = @([System.DayOfWeek]::Monday..[System.DayOfWeek]::Friday)
[System.DayOfWeek[]]$WeekDays = [System.DayOfWeek]::Friday
New-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ScheduleName -StartTime $StartTime -WeekInterval 1 -DaysOfWeek $WeekDays

###############################################################################
# Get-AzAutomationSchedule
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/get-azautomationschedule?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"

Get-AzAutomationSchedule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName

###############################################################################
# Link Runbook with Schedule
###############################################################################
#https://learn.microsoft.com/en-us/powershell/module/az.automation/register-azautomationscheduledrunbook?view=azps-14.3.0
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$Runbook = "Demo_Runbook"
$ScheduleName = "Daily"

Register-AzAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -RunbookName $Runbook -ScheduleName $ScheduleName

###############################################################################
# Hybrid Worker
###############################################################################
# https://blog.icewolf.ch/archive/2024/03/07/azure-automation-runbook-run-script-on-arc-enabled-server/


###############################################################################
# Create a HyridWorkerGroup with an Azure Arc Enabled Machine - ExtensionBased
# https://learn.microsoft.com/en-us/answers/questions/720043/how-to-deploy-arc-extension-microsoft-azure-automa
###############################################################################
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEMO"
$AutomationAccountName = "AutomationDemoPS"
$Token = (Get-AzAccesstoken).Token #Returns SecureString
$AccessToken = ConvertFrom-SecureString -SecureString $Token -AsPlainText
$hybridRunbookWorkerGroupName = "HyridWorkerGroupDemo01" # HRWG group to be created  
$ARCSubscriptionId = "1e467fc0-3227-4628-a048-fc5ef79bff93" #ARC machine Subscription ID
$ARCresourceGroupName = "RG_ARC" #ARC machine RG
$ARCmachineName = "ICESRV06" #ARC machine name
$ARCMachinelocation = "westeurope" # ARC Machine location
$ARCServerResourceId = "/subscriptions/$ARCSubscriptionId/resourceGroups/$ARCresourceGroupName/providers/Microsoft.HybridCompute/machines/$ARCmachineName"

#Create HRW Group URI
Write-Host "Create Hybrid Worker Group" -ForegroundColor Green
$headers = @{Authorization = "Bearer $AccessToken"}
$createHRWGroupuri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$automationAccountName/hybridRunbookWorkerGroups/$($hybridRunbookWorkerGroupName)?api-version=2024-10-23"
$contentType = "application/json"
$body = @{} | ConvertTo-Json
$response = Invoke-WebRequest -Uri $createHRWGroupuri -Method PUT -Headers $headers -Body $body -ContentType $contentType  
$response.Content

#To Confirm HRW Group Creation
Write-Host "Confirm Hybrid Worker Group" -ForegroundColor Green
(Invoke-WebRequest -Uri $createHRWGroupuri -Method Get -Headers $headers).Content

#Generate HRW id
$hrwId = New-Guid

#Create HRW URI
Write-Host "Create Hybrid Worker Group URI" -ForegroundColor Green
$createHRWuri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$automationAccountName/hybridRunbookWorkerGroups/$hybridRunbookWorkerGroupName/hybridRunbookWorkers/$($hrwId)?api-version=2024-10-23"

$body = @"
{
"properties":{"vmResourceId": "$ARCServerResourceId"}
}
"@

$response = Invoke-WebRequest -Uri $createHRWuri -Method PUT -Headers $headers -Body $body -ContentType $contentType
$response.Content

#To Confirm HRW Creation make a get
Write-Host "Confirm Hybrid Worker Group" -ForegroundColor Green
(Invoke-WebRequest -Uri $createHRWuri -Method Get -Headers $headers).Content

##### HRW is not Visible yet in the portal#####
Write-Host "Add Azure Automation Windows Hybrid Worker Extension to Arc Machine" -ForegroundColor Green
#Retrieve Automation Account Hybrid URL
$automationAccountInfouri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$($automationAccountName)?api-version=2024-10-23"  
$automationHybridServiceUrl = ((Invoke-WebRequest -Uri $automationAccountInfouri -Method Get -Headers $headers).Content) | ConvertFrom-Json | Select -expand properties | Select -expand automationHybridServiceUrl  
$automationHybridServiceUrl

$CreateARCExtensionUri = "https://management.azure.com/subscriptions/$ARCSubscriptionId/resourceGroups/$ARCresourceGroupName/providers/Microsoft.HybridCompute/machines/$ARCmachineName/extensions/HybridWorkerExtension?api-version=2025-01-13"
$CreateARCExtensionBody = @{
    'location'   = $($ARCMachinelocation)
    'properties' = @{
        'publisher'               = 'Microsoft.Azure.Automation.HybridWorker'
        'type'                    = 'HybridWorkerForWindows'
        'typeHandlerVersion'      = '1.3.63'
        'autoUpgradeMinorVersion' = $false
        'enableAutomaticUpgrade'  = $true
        'settings'                = @{
            'AutomationAccountURL' = $automationHybridServiceUrl
        }
    }
} | ConvertTo-Json -depth 2

#Create the Extension  
Invoke-WebRequest  -Uri $CreateARCExtensionUri -Method "PUT" -Headers $headers -Body $CreateARCExtensionBody -ContentType $contentType

#Check Azure ARC Extension
Install-PSResource Az.ConnectedMachine -Scope CurrentUser
Select-AzSubscription "1e467fc0-3227-4628-a048-fc5ef79bff93"
Get-AzConnectedMachine
Get-AzConnectedMachineExtension -ResourceGroupName "RG_ARC" -MachineName "ICESRV06"
Remove-AzConnectedMachineExtension -ResourceGroupName "RG_ARC" -MachineName "ICESRV06" -Name "HybridWorkerExtension"

#Code for Testing
Get-Host
$env:computername
Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IpV4" -and $_.AddressState -eq "preferred"} | Select-Object IPAddress