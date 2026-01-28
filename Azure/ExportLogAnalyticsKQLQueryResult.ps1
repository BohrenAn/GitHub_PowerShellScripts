###############################################################################
# ExportLogAnalyticsKQLQueryResult.ps1
# Run KQL Query with PowerShell against Azure LogAnalytics
# https://blog.icewolf.ch/archive/2026/01/20/azure-log-analytics-KQL-query-with-powershell/
# 2026-01-20 - Initial Version - Andres Bohren
###############################################################################

###############################################################################
# Connect to Azure
###############################################################################
# Modules: Az.Accounts
# Entra App with Certificate Authentication
# Azure Permissions: Log Analytics Data Reader
$ApplicationId = "113d9640-ede1-4be7-9bf2-c63a0028f7ed" #PowerShell-LogAnalytics
$TenantId = "icewolfch.onmicrosoft.com"
$Thumbprint = "A3A07A3C2C109303CCCB011B10141A020C8AFDA3" #O365Powershell4
Connect-AzAccount -CertificateThumbprint $Thumbprint -ApplicationId $ApplicationId -Tenant $TenantId -ServicePrincipal

###############################################################################
# Get Access Token
###############################################################################
$TokenLogAnalytics = Get-AzAccessToken -ResourceUrl "https://api.loganalytics.io"

If ($PSVersion -lt 6) {
    Write-Host "Running in PowerShell 5.1" -ForegroundColor Cyan
	$AccessToken = (New-Object System.Management.Automation.PSCredential("u",$TokenLogAnalytics.Token)).GetNetworkCredential().Password
} else {
    Write-Host "Running in PowerShell 5.1" -ForegroundColor Cyan
	$AccessToken = $TokenLogAnalytics.Token | ConvertFrom-SecureString -AsPlainText
}

#Get-JWTDetails -Token $AccessToken

###############################################################################
# KQl Query
###############################################################################
$KQLQuery = @"
SigninLogs 
| where TimeGenerated > ago(30d)
| where ResultType == 0
| summarize count() by UserId, UserPrincipalName
| order by count_ desc
"@

###############################################################################
# Compose REST Request for KQLQuery of LogAnalytics Workspace
###############################################################################
$WorkspaceID = "b5cbee97-c5ad-46a9-97a1-bb4d88e62dcb" #AADLogAnalytics-Icewolf
$EncodedQuery = [System.Web.HttpUtility]::UrlEncode($KQLQuery)
$URI = "https://api.loganalytics.io/v1/workspaces/$WorkspaceID/query?query=$EncodedQuery"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType

#$result.tables.columns
#$result.tables.rows

###############################################################################
# Convert Result to Array
###############################################################################
$cols = $result.tables.columns.name

$ResultArray = $result.tables.rows | ForEach-Object {
    $rowHash = [ordered]@{}
    for ($c = 0; $c -lt $cols.Count; $c++) {
        $rowHash[$cols[$c]] = $_[$c]
    }
    [pscustomobject]$rowHash
}

# Preview
$ResultArray

# Export-CSV
$ResultArray | Export-CSV -Path ".\KQLExport.csv" -Encoding UTF8 -NoTypeInformation