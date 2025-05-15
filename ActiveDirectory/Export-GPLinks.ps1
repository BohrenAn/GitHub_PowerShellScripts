###############################################################################
# Export-GPLinks.ps1
# Version: 1.0
# Date: 2025-05-15
# Author: Andres Bohren
# Description: This script will export all GPO links to a CSV file.
# Some Source code from here https://www.easy365manager.com/get-gpo-links-with-powershell/
###############################################################################
#Get-GPO -Name <GPOName>
#[xml]$Report = $GPO | Get-GPOReport -ReportType XML
#$Report.GPO.LinksTo

<#
    .SYNOPSIS
    This script will export all GPO links to a CSV file.

    .DESCRIPTION
    This script will export all GPO links to a CSV file.

    .PARAMETER GPOName
    [string]GPOName specifies the name of the GPO to export. If not provided, all GPOs will be exported.

    .LINK
    https://github.com/BohrenAn/GitHub_PowerShellScripts/tree/main/ActiveDirectory/Export-GPLinks.ps1

    .EXAMPLE
    .\Export-GPLinks.ps1 -GPOName <GPOName>
    This will export the GPO links for the specified GPO to a CSV file.

    .\Export-GPLinks.ps1
    This will export all GPO links to a CSV file.
#>

#Parameter
[CmdletBinding()]
Param (
    [parameter(mandatory = $false)][string]$GPOName
)

#Check if the Parameter GPOName is provided
If ($GPOName -ne "")
{
    [Array]$GPOs = Get-GPO -Name $GPOName
    If ($null -eq $GPO)
    {
        Write-Host "GPO not found: $GPOName" -ForegroundColor Red
        Exit
    }
} else {
    Write-Host "No GPO name provided, exporting all GPOs." -ForegroundColor Yellow
    #Get all GPOs
    [Array]$GPOs = Get-GPO -All
}

#Loop through the GPOs and create the CSV Export

#Create the CSV file
$OutputFile = ".\GPLinks.csv"
"Name;LinkPath;ComputerEnabled;UserEnabled;WmiFilter" | Out-File $OutputFile
$TotalGPO = $GPOs.Count
$INT = 0

#Loop through the GPOs
Foreach ($GPO in $GPOs)
{
	$Int = $INT + 1
	$GPODisplayName = $GPO.DisplayName
	Write-Host "Working on: $GPODisplayName [$INT/$TotalGPO]" -ForegroundColor Green
	[xml]$Report = $GPO | Get-GPOReport -ReportType XML
	$Links = $Report.GPO.LinksTo
	If ($Null -ne $Links)
	{
		ForEach($Link In $Links)
		{
			#A Line for each Link
			$Output = $Report.GPO.Name + ";" + $Link.SOMPath + ";" + $Report.GPO.Computer.Enabled + ";" + $Report.GPO.User.Enabled + ";" + $_.WmiFilter.Name
			$Output | Out-File $OutputFile -Append
		}
	} else {
			#No Links
			$Output = $Report.GPO.Name + ";;" + $Report.GPO.Computer.Enabled + ";" + $Report.GPO.User.Enabled + ";" + $_.WmiFilter.Name
			$Output | Out-File $OutputFile -Append
	}
}
