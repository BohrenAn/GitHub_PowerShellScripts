###############################################################################
# Update AzureFunction ExtensionBundle Version
# 2925-11-25 Initilial Version - Andres Bohren - https://blog.icewolf.ch
###############################################################################
Function Update-AZFunctionExtensionBundle {
    param(
        [Parameter(Mandatory=$true)] [string] $ResourceGroup,
        [Parameter(Mandatory=$true)] [string] $FunctionAppName,
        [Parameter(Mandatory=$false)] [string] $ExtensionBundleVersion = "[4.0.0, 5.0.0]"
    )

    # Get a token for the Kudu (SCM) site
    $Token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
    $AccessToken = ConvertFrom-SecureString $Token -AsPlainText
    $headers = @{ Authorization = "Bearer $AccessToken" }

    # Kudu VFS endpoint to host.json
    $scmBase = "https://$FunctionAppName.scm.azurewebsites.net"
    $vfsHost = "$scmBase/api/vfs/site/wwwroot/host.json"

    # Initialize Variable
    $hostJsonText = $null

    try {
        #Read current host.json (if it exists)
        $hostJsonText = Invoke-RestMethod -Uri $vfsHost -Headers $headers -Method "GET" -ErrorAction Stop 
        $hostJsonText
        #Change ExtensionBundleVersion
        $hostJsonText.extensionBundle.version = $ExtensionBundleVersion

        # Serialize
        $body = $hostJsonText | ConvertTo-Json -Depth 20
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)

        # Write back (overwrite) via Kudu VFS
        Invoke-RestMethod `
        -Uri $vfsHost `
        -Headers @{ Authorization = "Bearer $AccessToken"; "If-Match" = "*"} `
        -Method "PUT" `
        -Body $bytes `
        -ContentType "application/octet-stream"

        Write-Host "Updated $FunctionAppName host.json extensionBundle to $DesiredBundleRange" -ForegroundColor Green

        } catch {
            Write-Host "Failed to update $FunctionAppName host.json extensionBundle" -ForegroundColor Red
        }
}

# Connect to Azure with AZ PowerShell Module
Connect-AzAccount -Tenant icewolfch.onmicrosoft.com

# List Subscriptions
Get-AzSubscription -TenantId "46bbad84-29f0-4e03-8d34-f6841a5071ad"

# Select the Subscription
Select-AzSubscription -SubscriptionId "b1a6f1e3-2f3d-4e2b-908e-6f3c8f3c8e3d" 

# Call the Function
$RGName = "RG_MTASTS2"
$FunctionAppName = "IRGENDWOIMINTERNET-MTASTS"
Update-AZFunctionExtensionBundle -ResourceGroup $RGName -FunctionAppName $FunctionAppName