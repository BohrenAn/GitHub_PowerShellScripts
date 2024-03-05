<#
$SubscriptionID = "42ecead4-eae9-4456-997c-1580c58b54ba"
$ResourceGroupName = "RG_DEV"
$AutomationAccountName =  "icewolfautomation"
$URI = "https://westcentralus.management.azure.com/subscriptions/" + $SubscriptionID + "/resourceGroups/" + $ResourceGroupName + "/providers/Microsoft.Automation/automationAccounts/" + $AutomationAccountName + "?api-version=2021-06-22"
Invoke-WebRequest -URL $URI -Method "GET"
Invoke-AzRestMethod -Uri $URI -Method "GET"

az rest -m GET -u 'https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Automation/automationAccounts/{automationAccountName}?api-version=2021-06-22'

az login --scope https://management.core.windows.net//.default
az rest -m GET -u 'https://management.azure.com/subscriptions/42ecead4-eae9-4456-997c-1580c58b54ba/resourceGroups/RG_DEV/providers/Microsoft.Automation/automationAccounts/icewolfautomation?api-version=2021-06-22'

$settings = @{
    "AutomationAccountURL"  = "<registrationurl>";    
    "ProxySettings" = @{
        "ProxyServer" = "<ipaddress>:<port>";
        "UserName"="test";
    }
};
$protectedsettings = @{
"ProxyPassword" = "password";
};

"automationHybridServiceUrl": "https://6e16f5b9-0150-47bc-b250-90a4e21d2aef.jrds.we.azure-automation.net/automationAccounts/6e16f5b9-0150-47bc-b250-90a4e21d2aef"
RegistrationUrl": "https://6e16f5b9-0150-47bc-b250-90a4e21d2aef.agentsvc.we.azure-automation.net/accounts/6e16f5b9-0150-47bc-b250-90a4e21d2aef"

$settings = @{
    AutomationAccountURL = "https://6e16f5b9-0150-47bc-b250-90a4e21d2aef.jrds.we.azure-automation.net/automationAccounts/6e16f5b9-0150-47bc-b250-90a4e21d2aef"
}
New-AzConnectedMachineExtension -ResourceGroupName "RG_ARC" -Location "westeurope" -MachineName "ICESRV04" -Name "HybridWorkerExtension" -Publisher "Microsoft.Azure.Automation.HybridWorker" -ExtensionType HybridWorkerForWindows -TypeHandlerVersion 1.1 -Setting $settings -NoWait -EnableAutomaticUpgrade
New-AzConnectedMachineExtension -ResourceGroupName "RG_ARC" -Location "westeurope" -MachineName "Win2025" -Name "HybridWorkerExtension" -Publisher "Microsoft.Azure.Automation.HybridWorker" -ExtensionType HybridWorkerForWindows -TypeHandlerVersion 1.1 -Setting $settings -NoWait -EnableAutomaticUpgrade


New-AzConnectedMachineExtension -ResourceGroupName <VMResourceGroupName> -Location <VMLocation> -MachineName <VMName> -Name "HybridWorkerExtension" -Publisher "Microsoft.Azure.Automation.HybridWorker" -ExtensionType HybridWorkerForWindows -TypeHandlerVersion 1.1 -Setting $settings -NoWait -EnableAutomaticUpgrade

New-AzConnectedMachineExtension -ResourceGroupName "RG_ARC" -Location "westeurope" -MachineName "Win2025" -Name "HybridWorkerExtension" -Publisher "Microsoft.Azure.Automation.HybridWorker" -ExtensionType HybridWorkerForWindows -TypeHandlerVersion 1.1 -NoWait -EnableAutomaticUpgrade


$env:computername
Get-NetIPAddress

#>

###############################################################################
# Create a HyridWorkerGroup with an Azure Arc Enabled Machine - ExtensionBased
# https://learn.microsoft.com/en-us/answers/questions/720043/how-to-deploy-arc-extension-microsoft-azure-automa
###############################################################################
#Connect to Azure
Write-Host "Connect to Azure" -ForegroundColor Green
Connect-AzAccount
 
#Varialbles
$subscriptionId = "42ecead4-eae9-4456-997c-1580c58b54ba" #Automation Account sub id  
$resourceGroupName = "RG_DEV" #Automation Account RG  
$automationAccountName = "icewolfautomation" #Automation account name 
$token = (get-azaccesstoken).Token  
$hybridRunbookWorkerGroupName = "HyridWorkerGroupDemo" # HRWG group to be created  
$ARCSubscriptionId = "62585cfc-6e5b-48f7-bcb9-72cfad8dac0d" #ARC machine sub id  
$ARCresourceGroupName = "RG_ARC" #ARC machine RG  
$ARCmachineName = "ICESRV04" #ARC machine name  
$ARCMachinelocation = "westeurope" # ARC Machine location  
$ARCServerResourceId = "/subscriptions/62585cfc-6e5b-48f7-bcb9-72cfad8dac0d/resourceGroups/RG_ARC/providers/Microsoft.HybridCompute/machines/ICESRV04" #/subscriptions/$ARCSubscriptionId/resourceGroups/$ARCresourceGroupName/providers/Microsoft.HybridCompute/machines/$ARCmachineName
#Update all the above varialbles before using the below script  

  
#Create HRW Group URI  
Write-Host "Create Hybrid Worker Group" -ForegroundColor Green
$headers = @{Authorization = "Bearer $token"}  
$createHRWGroupuri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$automationAccountName/hybridRunbookWorkerGroups/$($hybridRunbookWorkerGroupName)?api-version=2021-06-22"  
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
$createHRWuri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$automationAccountName/hybridRunbookWorkerGroups/$hybridRunbookWorkerGroupName/hybridRunbookWorkers/$($hrwId)?api-version=2021-06-22"  
  
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
$automationAccountInfouri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Automation/automationAccounts/$($automationAccountName)?api-version=2021-06-22"  
$automationHybridServiceUrl = ((Invoke-WebRequest -Uri $automationAccountInfouri -Method Get -Headers $headers).Content) | ConvertFrom-Json | Select -expand properties | Select -expand automationHybridServiceUrl  
$automationHybridServiceUrl  
  
$CreateARCExtensionUri = "https://management.azure.com/subscriptions/$ARCSubscriptionId/resourceGroups/$ARCresourceGroupName/providers/Microsoft.HybridCompute/machines/$ARCmachineName/extensions/HybridWorkerExtension?api-version=2021-05-20"  
$CreateARCExtensionBody = @{  
    'location'   = $($ARCMachinelocation)  
    'properties' = @{  
        'publisher'               = 'Microsoft.Azure.Automation.HybridWorker'  
        'type'                    = 'HybridWorkerForWindows'  
        'typeHandlerVersion'      = '1.1.13'
        'autoUpgradeMinorVersion' = $false  
        'enableAutomaticUpgrade'  = $true  
        'settings'                = @{  
            'AutomationAccountURL' = $automationHybridServiceUrl  
        }  
    }  
} | ConvertTo-Json -depth 2  
  
#Create the Extension  
Invoke-WebRequest  -Uri $CreateARCExtensionUri -Method PUT -Headers $headers -Body $CreateARCExtensionBody -ContentType $contentType
