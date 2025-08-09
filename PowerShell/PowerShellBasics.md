# PowerShell Basics

## Integrated Help

```pwsh
Get-Help
Get-Help Get-Date
Get-Help *
```

## List all cmdlets

```pwsh
Get-Command
Get-Command -Module MicrosoftTeams
```

## Powershell Version

```pwsh
Get-Host | Select-Object Version
```

## Execution Policy

```pwsh
Get-Help about_signing
Get-ExecutionPolicy
Set-ExecutionPolicy Unrestricted | RemoteSigned | AllSigned | Restricted | Default | Bypass | Undefined
Set-ExecutionPolicy RemoteSigned
```

| Policy Wert | Beschreibung |
| --- | --- |
| Restricted (Default) | Keine Skripte werden ausgeführt |
| Allsigned | Nur signierte Skripte werden ausgeführt |
| RemoteSigned | Lokal erstellte Skripte sind erlaubt, aber andere Skripte müssen signiert sein |
| Unrestricted | Jedes Skript wird ausgeführt |

## Powershell Datatypes

|Datatype | Beschreibung |
| --- | --- |
| [string] | Fixed-length string of Unicode characters |
| [char] | A Unicode 16-bit character |
| [byte] | An 8-bit unsigned character |
| [int]    | 32-bit signed integer |
| [long] | 64-bit signed integer |
| [bool] | Boolean True/False value |
| [decimal] | A 128-bit decimal value |
| [single] | Single-precision 32-bit floating point number |
| [double] | Double-precision 64-bit floating point number |
| [DateTime] | Date and Time |
| [xml] | Xml object |
| [array] | An array of values |
| [hashtable] | Hashtable object |

## Compare Operator

| Operator | Beschreibung |
| --- | --- |
| -lt | Less than |
| -le | Less than or equal to |
| -gt | Greater than |
| -ge | Greater than or equal to |
| -eq | Equal to |
| -ne | Not Equal to |
| -contains | Determine elements in a group. Contains always returns Boolean $True or $False |
| -notcontains | Determine excluded elements in a group This always returns Boolean $True or $False |
| -like | Like - uses wildcards for pattern matching |
| -notlike | Not Like - uses wildcards for pattern matching |
| -match | Match - uses regular expressions for pattern matching |
| -notmatch | Not Match - uses regular expressions for pattern matching |
| -band    | Bitwise AND |
| -bor | Bitwise OR |
| -is | Is of Type  |
| -isnot | Is not of Type |

## Operator

| Operator | Beschreibung |
| --- | --- |
| \# | The hash key is for comments |
| \+ | Add  |
| \- | Subtract |
| \* | Multiply |
| / | Divide |
| % | Modulus (Some call it Modulo) - Means remainder 17 % 5 = 2 Remainder |
| = | equal |
| -not | logical not equal |
| ! | logical not equa |
| -replace | Replace (e.g.  "abcde" -replace "b","B") (case insensitive) |
| -ireplace | Case-insensitive replace (e.g.  "abcde" -ireplace "B","3") |
| -creplace | Case-sensitive replace (e.g.  "abcde" -creplace "B","3") |
| -and | AND (e.g. ($a -ge 5 -AND $a -le 15) ) |
| -or | OR  (e.g. ($a -eq "A" -OR $a -eq "B") ) |
| -as | convert to type (e.g. 1 -as [string] treats 1 as a string ) |
| .. | Range operator |
| & | call operator |
| . (space) | call operator (e.g. $a = "Get-ChildItem" . $a executes Get-ChildItem in the current scope) |
| . | for an objects properties $CompSys.TotalPhysicalMemory |
| -F | Format operator |

## Pipe

```pwsh
Get-Service | fl name, status
Get-Service | ft name, status
```

## Pipe Output to clipboard

```pwsh
Get-Service | clip
```

## Sort

```pwsh
Get-Service | Sort-Object -Property status
```

## Select

```pwsh
$Services = Get-Service
$Services[0] | Format-List
$Services | Select-Object Name, DisplayName, Status

#SubProperty
$Object | select-object @{Name="Property1"; Expression={$_.PropertyObject.Property1}}
```

## Where

```pwsh
Get-Service | Where-Object {$_.status -eq "Running"}
```

## Count Objects

```pwsh
Get-Service | Where-Object {$_.status -eq "Running"} | Measure-Object
```

## Output

```pwsh
Write-Host "Test"
Write-Host "Test" -ForegroundColor "Green"
```

## Output in HTML

```pwsh
Get-Service | ConvertTo-Html -Property Name,Status > D:\Temp\Service.html
```

## Input

```pwsh
$a = Read-Host "Enter your name"
Write-Host "Hello" $a
```

## Import-CSV

```pwsh
$Header = "Vorname", "Nachname"
$csv = Import-Csv c:\mitarbeiter.csv -Header $header -Delimiter ";"
```

## Export-CSV

```pwsh
Get-ADUser | select-object sn, givenName, title | export-csv C:\ad-name-title.csv -encoding UTF8 -NoTypeInformation
```

## Filesystem

```pwsh
cd c:\temp
Get-ChildItem
Get-ChildItem -Exclude .mp3
New-Item C:\Test\Powershell -type directory
Test-Path C:\Temp\somefile.txt
```

## Delete File if exist

```pwsh
$CSVFile = ".\demo.csv"
If (Test-Path -Path $CSVFile)
{
    Remove-Item -Path $CSVFile
}
```

## Read from File

```pwsh
[string]\$Attachment = Get-Content C:\Attachment_small.txt
$sw = new-object system.IO.StreamWriter($LogPath, 1)
$sw.readline("Just a new Line")
$sw.close()
```

## Out-File

```pwsh
$a = "Hello world"
$a | out-file test.txt
```

## WriteToFile

```pwsh
$sw = new-object system.IO.StreamWriter($LogPath, 1)
$sw.writeline("Just a new Line")
$sw.close()
```

## Content

```pwsh
$CSVFile = "C:\Temp\test.txt"
Set-Content -Path $CSVFile -Value "Header1;Header2;Header3"
Add-Content -Path $CSVFile -Value "$Var1;$Var2;$Var3"
Get-Content -Path $CSVFile
```

## Replace

```pwsh
$test = "This is just a test"
$test= $test.Replace("test", "text")
$test
```

## Split

```pwsh
$domuser = "DOMAIN\widmanaf"
$arr = $domuser.split("\")
$domain = $arr[0]
$sam = $arr[1]
```

## DNS

```pwsh
#Resolve-DnsName does only work on Windows
Resolve-DnsName -Name "www.facebook.com"
Resolve-DnsName -Name "www.facebook.com" -Server 8.8.8.8
Resolve-DnsName -Name "www.facebook.com" -Server 8.8.8.8 -Type "MX"

#Get your Public IP
(Resolve-DnsName -Name "myip.opendns.org").IPAddress
```

## Registry

```pwsh
Get-ItemProperty -path "REGISTRY::\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing\" -name State
Get-ItemProperty -path "REGISTRY::\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing\" -name State -value 146944
```

## WMI

```pwsh
Get-WMIObject -Class Win32_Computersystem
```

## Date

```pwsh
[datetime]$datum = "11/01/2012"
$Datum = get-date
$Datum = (Get-Date).addDays(5)
$Datum =  $(get-date -format "dd.MM.yyyy HH:mm:ss")
```

## If Else

```pwsh
If ($Count -gt 0) {
    Write-Host("Computer " + $Computername + " found") -foregroundcolor Green
} else {
    Write-Host("Computer " + $Computername + " NOT found") -foregroundcolor Red
}
```

## Condition

```pwsh
$a = "red"
switch ($a)
{
    "red" {"The colour is red"}
    "white"{"The colour is white"}
    default{"Another colour"}
}
```

## Match

```pwsh
$string = "Just a little string"
$searchstring = "little"
$result = $string -match $searchstring #Result is TRUE
```

## For Each

```pwsh
Foreach ($Item in $Items)
{
    Write-Host("Do whatever you want")
}
```

## Range

```pwsh
$range = 1..2000
ForEach ($iterator in $range) 
{
    $Groupname = "Group" + "{0:D4}" -f $iterator
    New-QADGroup -Name $groupname -SamAccountName $groupname -ParentContainer 'OU=Groups,OU=TEST,DC=destination,DC=internal' -Member j.doe
}
```

## Do While

```pwsh
$a=1
Do {$a; $a++}
While ($a –lt 10)
```

## Do Until

```pwsh
$a=1
Do {$a; $a++}
Until ($a –gt 10)
```

## Array

> Is depreciated

```pwsh
#Arrays are depreciated and should not be used anymore - they also have a bad performance

#Initialize Array
[array]$myarray = @()
#Bad Performance because a new Array is created and the values are copied
$myarray += "A"
$myarray += "B"
$myarray.GetType()
$myarray
$myarray[0]
```

### Arraylist

> Is depreciated

```pwsh
#Arraylists are depreciated
$ArrayList = [System.Collections.ArrayList]@()
$ArrayList.Add("Value1")
$ArrayList.Add("Value2")
$ArrayList
$ArrayList[0]
```

### List

```pwsh
$MyList = [System.Collections.Generic.List[object]]::new()
$MyList = [System.Collections.Generic.List[int]]::new()
$MyList = [System.Collections.Generic.List[string]]::new()
$MyList.Add("Value1")
$MyList.Add("Value2")
$MyList.Add("Value3")
$MyList
$MyList[0]
$MyList.Remove("Value2")
$MyList
```

### String from Array

> Requires PowerShell 7.x

```pwsh
$StringFromArray = $MyList  | Join-String -Separator ","
$StringFromArray
```

## Hashtable

```pwsh
#Initialize Hashtable (Key / Value Pair) > Key needs to be unique
$ageList = @{}

#Add Values
$key = 'Kevin'
$value = 36
$ageList.add( $key, $value )

#Another Way to add Values
$ageList.add( 'Alex', 9 )

#Search for Key
$ageList['Alex']

#Create Hashtable with Value
$ageList = @{
    Kevin = 36
    Alex  = 9
}
```

## PSCustomObject

```pwsh
$myObject = [PSCustomObject]@{
    Name     = 'Kevin'
    Language = 'PowerShell'
    State    = 'Texas'
}
```

Converting Hashtable to PSCustomObject

```pwsh
$myHashtable = @{
    Name     = 'Kevin'
    Language = 'PowerShell'
    State    = 'Texas'
}
$myObject = [pscustomobject]$myHashtable
```

## Powershell Snapin

```pwsh
#Check if Forefront Snapin is already loaded
$Snapins = get-pssnapin
if ($Snapins -match "FSSPSSnapin")
    {
        Write-Output $("Forefront PS Snapin already loaded")
    }
    else
    {
        Write-Output $("Loading Forefront PS Snapin")
        Add-PsSnapin FSSPSSnapin
    }
```

## Pause / Press any key

```pwsh
#Pause
Start-Sleep -Seconds 15

#Not supported by ISE
Write-Host "Press any key to continue..."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

#Supported by ISE
read-host "Press ENTER to continue..."
```

## Eventlog

```pwsh
Get-EventLog System -Newest 10
```

## Garbage Collector

```pwsh
[System.GC]::Collect()
```

## COM Objekte

```pwsh
$a = New-Object –comobject "wscript.network"
$a.username
```

## Credential

```pwsh
$Cred = Get-Credential
$Username = "domain\username"
$Password = ConvertTo-SecureString -String "YourPassword" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential $Username,$Password
```

## Securestring

```pwsh
$Password = ConvertTo-SecureString "Pass@word1" -AsPlainText -Force
```

## Enrypt/Decrypt and store Password in a safe way

```pwsh
###############################################################################
# This script demonstrates how to encrypt and decrypt a password using PowerShell.
# Note: The decryption will only work on the same machine and user context
###############################################################################
#Ecrypting a Plain Text password
$Password = "ABC"
$SecureString = $Password | ConvertTo-SecureString -AsPlainText -Force
$EncryptedString = $SecureString | ConvertFrom-SecureString
$EncryptedString
# Save the encrypted string to a file
$EncryptedString | Out-File -FilePath ".\EncryptedPassword.txt"


###############################################################################
# Decrypting the password from the file and converting it back to plain text
###############################################################################
$EncryptedString = Get-Content -Path ".\EncryptedPassword.txt"
$DecryptedString = $EncryptedString | ConvertTo-SecureString
$DecryptedPassword = $DecryptedString | ConvertFrom-SecureString -AsPlainText
$DecryptedPassword
```

## Properties from Sub Objects

```pwsh
Connect-MgGraph -NoWelcome
$MgUser = Get-MgUser -UserId m.muster@icewolf.ch -Property DisplayName, Id, Mail, UserPrincipalName, AssignedLicenses
$MgUser | ft UserPrincipalName, @{Name="DisabledPlans";Expression={$_.AssignedLicenses.DisabledPlans}},@{Name="SKUID";Expression={$_.AssignedLicenses.skuid}}
```

## Run a Script

```pwsh
powershell.exe "c:\myscript.ps1"
```

## Parameter

```pwsh
myscript.ps1 server1 username
$servername = $args[0]
$username = $args[1]
```

## Function

```pwsh
function sum ([int]$a,[int]$b)
{
    $result = $a + $b
    return $result
}
sum 4 5
```

## Funktion WriteLog

```pwsh
###############################################################################
# Function WriteLog
###############################################################################
Function WriteLog {
 PARAM (
 [string]$pLogtext
 )
    $pDate =  $(get-date -format "dd.MM.yyyy HH:mm:ss")
      
    $sw = new-object system.IO.StreamWriter($LogPath, 1)
    $sw.writeline($pDate + " " + $pLogtext)
    $sw.close()
}
```

## SQL Querys

```pwsh
###############################################################################
# SQL Query's with Powershell
###############################################################################
#Setup SQL Connection
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
#$SqlConnection.ConnectionString = "Data Source=ICESRV02;database=db_test;Uid=myusername;Pwd=mypassword"
#Use this Windows Authentication
$SqlConnection.ConnectionString = "Data Source=ICESRV02;database=db_test;Integrated Security=SSPI;"  
$SqlConnection.Open()
 
#SQL SELECT
$qSQL = "SELECT fID, fVorname, fNachname FROM tUsers"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $qSQL
$SqlCmd.Connection = $SqlConnection
$SQLReader = $SqlCmd.ExecuteReader()
while ($sqlReader.Read()) 
{
    $Column1 = $sqlReader["Column1"]
    $Column2 = $sqlReader["Column2"]
    Write-Host "Column1: $Column1 / Column2: $Column2"
}
$SQLReader.close()

#SQL INSERT
$qSQL = "INSERT INTO tUsers (fVorname, fNachname) VALUES ('Hans', 'Muster')"
$SqlCmd.CommandText = $qSQL
$Result = $SqlCmd.ExecuteNonQuery()
Write-Host "Result INSERT: " $Result

#SQL UPDATE
$qSQL = "UPDATE tUsers SET fVorname = 'Fritz', fNachname = 'Meier' WHERE fNachname = 'Muster'"
$SqlCmd.CommandText = $qSQL
$Result = $SqlCmd.ExecuteNonQuery()
Write-Host "Result UPDATE: " $Result

#SQL connection Close
$SqlConnection.Close()
```

## JSON

Convert JSON to Object

```pwsh
#Convert JSON
$Filetypes = Get-Content -Path E:\temp\FileTypes.json | Out-String | ConvertFrom-Json
```

## Odata.NextLink

On the Example of [M365 neue Service Health und Communications API in Microsoft Graph](https://blog.icewolf.ch/archive/2021/08/24/m365-neue-service-health-und-communications-api-in-microsoft-graph/)

```pwsh
#Messages
$URI = "https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/messages"
$ContentType = "application/json"
$Headers = @{"Authorization" = "Bearer "+ $AccessToken}
$result = Invoke-RestMethod -Method "GET" -Uri $uri -Headers $Headers -ContentType $ContentType


$AllMessages += $result.value

$INT = 0
if ($result.'@odata.nextLink') 
{    
    do {
        $INT = $INT + 1
        Write-Host "Invoke Odata.NextLink [$INT]"
        $result = (Invoke-RestMethod -Uri $result.'@odata.nextLink' -Headers $Headers -Method Get -ContentType $ContentType)
        $AllMessages += $result.value

    } until (
        !$result.'@odata.nextLink'
    )
}

$AllMessages
```
