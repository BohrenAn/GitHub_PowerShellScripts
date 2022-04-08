###############################################################################
# Extract GUID, String, ProductName from
# https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
# 08.04.2022 V0.1 - Initial Version - Andres Bohren
###############################################################################

###############################################################################
# Function Convert-FromHTMLTable
# https://github.com/ztrhgf/useful_powershell_functions/blob/master/ConvertFrom-HTMLTable.ps1
###############################################################################
function ConvertFrom-HTMLTable {
    <#
    .SYNOPSIS
    Function for converting ComObject HTML object to common PowerShell object.
    .DESCRIPTION
    Function for converting ComObject HTML object to common PowerShell object.
    ComObject can be retrieved by (Invoke-WebRequest).parsedHtml or IHTMLDocument2_write methods.
    In case table is missing column names and number of columns is:
    - 2
        - Value in the first column will be used as object property 'Name'. Value in the second column will be therefore 'Value' of such property.
    - more than 2
        - Column names will be numbers starting from 1.
    .PARAMETER table
    ComObject representing HTML table.
    .PARAMETER tableName
    (optional) Name of the table.
    Will be added as TableName property to new PowerShell object.
    .EXAMPLE
    $pageContent = Invoke-WebRequest -Method GET -Headers $Headers -Uri "https://docs.microsoft.com/en-us/mem/configmgr/core/plan-design/hierarchy/log-files"
    $table = $pageContent.ParsedHtml.getElementsByTagName('table')[0]
    $tableContent = @(ConvertFrom-HTMLTable $table)
    Will receive web page content >> filter out first table on that page >> convert it to PSObject
    .EXAMPLE
    $Source = Get-Content "C:\Users\Public\Documents\MDMDiagnostics\MDMDiagReport.html" -Raw
    $HTML = New-Object -Com "HTMLFile"
    $HTML.IHTMLDocument2_write($Source)
    $HTML.body.getElementsByTagName('table') | % {
        ConvertFrom-HTMLTable $_
    }
    Will get web page content from stored html file >> filter out all html tables from that page >> convert them to PSObjects
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.__ComObject] $table,

        [string] $tableName
    )

    $twoColumnsWithoutName = 0

    if ($tableName) { $tableNameTxt = "'$tableName'" }

    $columnName = $table.getElementsByTagName("th") | % { $_.innerText -replace "^\s*|\s*$" }

    if (!$columnName) {
        $numberOfColumns = @($table.getElementsByTagName("tr")[0].getElementsByTagName("td")).count
        if ($numberOfColumns -eq 2) {
            ++$twoColumnsWithoutName
            Write-Verbose "Table $tableNameTxt has two columns without column names. Resultant object will use first column as objects property 'Name' and second as 'Value'"
        } elseif ($numberOfColumns) {
            Write-Warning "Table $tableNameTxt doesn't contain column names, numbers will be used instead"
            $columnName = 1..$numberOfColumns
        } else {
            throw "Table $tableNameTxt doesn't contain column names and summarization of columns failed"
        }
    }

    if ($twoColumnsWithoutName) {
        # table has two columns without names
        $property = [ordered]@{ }

        $table.getElementsByTagName("tr") | % {
            # read table per row and return object
            $columnValue = $_.getElementsByTagName("td") | % { $_.innerText -replace "^\s*|\s*$" }
            if ($columnValue) {
                # use first column value as object property 'Name' and second as a 'Value'
                $property.($columnValue[0]) = $columnValue[1]
            } else {
                # row doesn't contain <td>
            }
        }
        if ($tableName) {
            $property.TableName = $tableName
        }

        New-Object -TypeName PSObject -Property $property
    } else {
        # table doesn't have two columns or they are named
        $table.getElementsByTagName("tr") | % {
            # read table per row and return object
            $columnValue = $_.getElementsByTagName("td") | % { $_.innerText -replace "^\s*|\s*$" }
            if ($columnValue) {
                $property = [ordered]@{ }
                $i = 0
                $columnName | % {
                    $property.$_ = $columnValue[$i]
                    ++$i
                }
                if ($tableName) {
                    $property.TableName = $tableName
                }

                New-Object -TypeName PSObject -Property $property
            } else {
                # row doesn't contain <td>, its probably row with column names
            }
        }
    }
}

###############################################################################
# Extract Table from MS Website
###############################################################################
Write-Output "Extract SKU Table from MS Website"
Try {
	$URI = "https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference"
	#$WebRequest = Invoke-WebRequest -URI $URI -UseBasicParsing
	$WebRequest = Invoke-WebRequest -URI $URI 
	
	#$WebRequest | get-member
	
	$tables = @($WebRequest.ParsedHtml.getElementsByTagName("TABLE"))
	$table = $tables[0]
	$MSServicePlan = ConvertFrom-HTMLTable $table
	$MSServicePlan | Format-Table "GUID","String ID","Product Name"
	$MSServicePlan |  Export-CSV -Path "C:\Temp\licensing-service-plan.csv" -Encoding UTF8 -NoTypeInformation
} 
catch [System.Net.WebException] { 
    Write-Verbose "An exception was caught: $($_.Exception.Message)"
    $_.Exception.Response 
} catch { 
	$ErrorMessage = $_.Exception.Message
    Write-Output "ErrorMessage: $ErrorMessage"
} 