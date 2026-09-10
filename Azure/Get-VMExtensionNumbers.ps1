###############################################################################
# Get Extension Version from Azure VM
# 07.06.2026 - V0.1 - Initial Script - Andres Bohren
# 10.09.2026 - V0.2 - Added SubscriptionId parameter and NeverVersionAvailable Property - Andres Bohren
###############################################################################
Function Get-VMExtensionNumbers {
    Param (
        [parameter(Mandatory=$true)][String]$SubscriptionId,
        [parameter(Mandatory=$true)][String]$ResourceGroupName,
        [parameter(Mandatory=$true)][String]$VMName
    )

    # Check if the specified subscription exists in the current context
    $Subscriptions = Get-AzSubscription -WarningAction SilentlyContinue
    If ($Subscriptions.Id -notcontains $SubscriptionId)
    {
        #Throw "SubscriptionId $SubscriptionId not found."
        Write-Host "SubscriptionId $SubscriptionId not found in current context." -ForegroundColor Red
        return
    } else {
        # Set the Azure context to the specified subscription
        $Null = Set-AzContext -SubscriptionId $SubscriptionId
    }

    # Check if Machine is running
    $AZVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
    $DisplayStatus = ($AZVM.Statuses | Where-Object {$_.Code -match "PowerState/"}).DisplayStatus
    If ($DisplayStatus -eq "VM deallocated")
    {
        Write-Host "VM is not Running. Needs to be running to get the Extensions." -ForegroundColor Red
    } else {
        # Get Extension
        $Extensions = Get-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $VMName
        $VMExtensionArray = [System.Collections.Generic.List[object]]::new()
        Foreach ($Extension in $Extensions)
        {
            $Name = $Extension.Name
            $Location = $Extension.Location
            $Publisher = $Extension.Publisher
            $ExtensionType = $Extension.ExtensionType
            $ResourceGroupName = $Extension.ResourceGroupName
            $ID = $Extension.id
            
            # Get Instance View
            $URI = $ID.Replace("/extensions/$Name","") + "`?api-version=2025-11-01&`$expand=instanceView"
            $Result = Invoke-AzRestMethod -Method "GET" -Path $URI
            $Object = $Result.Content | ConvertFrom-Json
            $InstanceViewExtensions = $Object.properties.instanceView.extensions
            $InstanceViewExtension = $InstanceViewExtensions | Where-Object {$_.Name -eq $Name}
            [version]$InstanceViewVersion = $InstanceViewExtension.TypeHandlerVersion
            #Write-Host "Extension: $Name"
            #Write-Host "Installed Version: $InstanceViewVersion"

            # Get Avaiable Versions
            $URI = $ID.split("resourceGroups/")[0] + "providers/Microsoft.Compute/locations/$Location/publishers/$Publisher/artifacttypes/vmextension/types/$ExtensionType/versions`?api-version=2025-11-01"
            $Result = Invoke-AzRestMethod -Method "GET" -Path $URI
            [version]$NewestVersion = ($Result.content | ConvertFrom-Json | Select-Object Name | Sort-Object {[version]$_.Name} -Descending).Name[0]
            #Write-Host "Newest Version: $NewestVersion"

            # Never Version available
            $NeverVersionAvailable = $false
            If ($InstanceViewVersion -lt $NewestVersion)
            {
                $NeverVersionAvailable = $true
            }

            $Version = [PSCustomObject]@{
                id = $ID
                name = $Name
                installedVersion = $InstanceViewVersion
                newestVersion = $NewestVersion
                neverVersionAvailable = $NeverVersionAvailable
            }
            $VMExtensionArray.Add($Version)
        }
        return $VMExtensionArray
    }
}

#Example Usage:
#$Result = Get-VMExtensionNumbers -SubscriptionId "42ecead4-eae9-4456-997c-1580c58b54ba" -ResourceGroupName rg-exolab -VMName EDGE01
#$Result | fl