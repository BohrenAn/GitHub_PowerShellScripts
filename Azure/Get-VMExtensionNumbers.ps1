###############################################################################
# Get Extension Version from Azure VM
# 07.06.2026 - V0.1 - Initial Script - Andres Bohren
###############################################################################
Function Get-VMExtensionNumbers {
    Param (
        [parameter(Mandatory=$true)][String]$ResourceGroupName,
        [parameter(Mandatory=$true)][String]$VMName
    )

    # Check if Machine is running
    $AZVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
    $DisplayStatus = ($AZVM.Statuses | where {$_.Code -match "PowerState/"}).DisplayStatus
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
            $InstanceViewExtension = $InstanceViewExtensions | where {$_.Name -eq $Name}
            $InstanceViewVersion = $InstanceViewExtension.TypeHandlerVersion
            #Write-Host "Extension: $Name"
            #Write-Host "Installed Version: $InstanceViewVersion"

            # Get Avaiable Versions
            $URI = $test.split("resourceGroups/")[0] + "providers/Microsoft.Compute/locations/$Location/publishers/$Publisher/artifacttypes/vmextension/types/$ExtensionType/versions`?api-version=2025-11-01"
            $Result = Invoke-AzRestMethod -Method "GET" -Path $URI
            $NewestVersion = ($Result.content | ConvertFrom-Json | Select-Object Name | Sort-Object {[version]$_.Name} -Descending).Name[0]
            #Write-Host "Newest Version: $NewestVersion"

            $Version = [PSCustomObject]@{
                id = $ID
                name = $Name
                installedVersion = $InstanceViewVersion
                newestVersion = $NewestVersion
            }
            $VMExtensionArray.Add($Version)
        }
        return $VMExtensionArray
    }
}
$Result = Get-VMExtensionNumbers -ResourceGroupName rg-exolab -VMName EDGE01
$Result | fl