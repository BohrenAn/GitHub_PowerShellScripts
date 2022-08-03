#Integrated Help
    Get-Help
    Get-Help Get-Date
    Get-Help *

#List all cmdlet
    Get-Command
    Get-Command -Module MicrosoftTeams

#Powershell Version
    Get-Host | Select-Object Version

#Execution Policy
    Get-Help about_signing
    Get-ExecutionPolicy
    Set-ExecutionPolicy Unrestricted | RemoteSigned | AllSigned | Restricted | Default | Bypass | Undefined
    Set-ExecutionPolicy RemoteSigned

Policy Wert	Beschreibung
Restricted (Default)	Keine Skripte werden ausgeführt
Allsigned	Nur signierte Skripte werden ausgeführt
RemoteSigned	Lokal erstellte Skripte sind erlaubt, aber andere Skripte müssen signiert sein
Unrestricted	Jedes Skript wird ausgeführt


#Powershell Datatypes
Datatype	Beschreibung
[string]	Fixed-length string of Unicode characters
[char]	A Unicode 16-bit character
[byte]	An 8-bit unsigned character
[int]	32-bit signed integer
[long]	64-bit signed integer
[bool]	Boolean True/False value
[decimal]	A 128-bit decimal value
[single]	Single-precision 32-bit floating point number
[double]	Double-precision 64-bit floating point number
[DateTime]	Date and Time
[xml]	 Xml object
[array]	An array of values
[hashtable]	Hashtable object

#Compare Operator
Operator	Beschreibung
-lt	Less than
-le	Less than or equal to
-gt	Greater than
-ge	Greater than or equal to
-eq	Equal to
-ne	Not Equal to
-contains	Determine elements in a group. Contains always returns Boolean $True or $False
-notcontains	Determine excluded elements in a group This always returns Boolean $True or $False
-like	Like - uses wildcards for pattern matching
-notlike	Not Like - uses wildcards for pattern matching
-match	Match - uses regular expressions for pattern matching
-notmatch	Not Match - uses regular expressions for pattern matching
-band	Bitwise AND
-bor	Bitwise OR
-is	Is of Type
-isnot	Is not of Type

#Operator

Operator	Beschreibung
\#	The hash key is for comments
\+	Add
\-	Subtract
\*	Multiply
/	Divide
%	Modulus (Some call it Modulo) - Means remainder 17 % 5 = 2 Remainder
=	equal
-not	logical not equal
!	logical not equa
-replace	Replace (e.g.  "abcde" -replace "b","B") (case insensitive)
-ireplace	Case-insensitive replace (e.g.  "abcde" -ireplace "B","3")
-creplace	Case-sensitive replace (e.g.  "abcde" -creplace "B","3")
-and	AND (e.g. ($a -ge 5 -AND $a -le 15) )
-or	OR  (e.g. ($a -eq "A" -OR $a -eq "B") )
-as	convert to type (e.g. 1 -as [string] treats 1 as a string )
..Range	operator (e.g.  foreach ($i in 1..10) {$i }  )
&	call operator (e.g. $a = "Get-ChildItem" &$a executes Get-ChildItem)
. (space)	call operator (e.g. $a = "Get-ChildItem" . $a executes Get-ChildItem in the current scope)
.	for an objects properties $CompSys.TotalPhysicalMemory
-F	Format operator (e.g. foreach ($p in Get-Process) { "{0,-15} has {1,6} handles" -F  $p.processname,$p.Handlecount } )

#Pipe
    Get-Service | fl name, status
    Get-Service | ft name, status

#Pipe Output to clipboard
    Get-Service | clip

#Sort
    Get-Service | Sort-Object -Property status

#Where
    Get-Service | Where-Object {$_.status -eq "Running"}

#Count Objects
    Get-Service | Where-Object {$_.status -eq "Running"} | Measure-Object

#Output
    Write-Host "Test"
    Write-Host "Test" -ForegroundColor "Green"

#Output in HTML
    get-service | ConvertTo-Html -Property Name,Status > D:\Temp\Service.html

#Input
    $a = Read-Host "Enter your name"
    Write-Host "Hello" $a

#Import-CSV
    $Header = "Vorname", "Nachname"
    $csv = Import-Csv c:\mitarbeiter.csv -Header $header

#Export-CSV
    Get-ADUser | select-object sn, givenName, title | export-csv C:\ad-name-title.csv -encoding UTF8 -NoTypeInformation

#Filesystem
    cd c:\temp
    Get-ChildItem
    Get-ChildItem -Exclude .mp3
    New-Item C:\Test\Powershell -type directory
    Test-Path C:\Temp\somefile.txt

#Read from File
    [string]\$Attachment = Get-Content C:\Attachment_small.txt
    $sw = new-object system.IO.StreamWriter($LogPath, 1)
    $sw.readline("Just a new Line")
    $sw.close()

#Out-File
    $a = "Hello world"
    $a | out-file test.txt

#WriteToFile
    $sw = new-object system.IO.StreamWriter($LogPath, 1)
    $sw.writeline("Just a new Line")
    $sw.close()

#Replace
    $test = "This is just a test"
    $test= $test.Replace("test", "text")
    $test
 
#Split
    $domuser = "RTS\widmanaf"
    $arr = $domuser.split("\")
    $domain = $arr[0]
    $sam = $arr[1]
 
#Registry
    Get-ItemProperty -path "REGISTRY::\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing\" -name State
    set-ItemProperty -path "REGISTRY::\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing\" -name State -value 146944

#WMI
    Get-WMIObject -Class Win32_Computersystem

#Datum
    [datetime]$datum = "11/01/2012"
    $Datum = get-date
    $Datum = (Get-Date).addDays(5)
    $Datum =  $(get-date -format "dd.MM.yyyy HH:mm:ss")

#If Else
       If ($Count -gt 0) {
            Write-Host("Computer " + $Computername + " found") -foregroundcolor Green
        } else {
            Write-Host("Computer " + $Computername + " NOT found") -foregroundcolor Red
        }

#Condition
    $a = "red"
    switch ($a)
    {
    "red" {"The colour is red"}
    "white"{"The colour is white"}
    default{"Another colour"}
    }

#Match
    $string = "Just a little string"
    $searchstring = "little"
    $result = $string -match $searchstring #Result is TRUE
    /*For Each*/       
    Foreach (Item in Items){
    Write-Host("Do whatever you want")
    }

#Range
    $range = 1..2000
    ForEach ($iterator in $range) {
    $groupname = "Group" + "{0:D4}" -f $iterator
    new-QADGroup -Name $groupname -SamAccountName $groupname -ParentContainer 'OU=Groups,OU=TEST,DC=destination,DC=internal' -Member j.doe
    }

#Do While
    $a=1
    Do {$a; $a++}
    While ($a –lt 10)

#Do Until
    $a=1
    Do {$a; $a++}
    Until ($a –gt 10)

#Array
    [array]$myarray = @()
    $myarray += "A"
    $myarray += "B"
    $myarray.GetType()
    $myarray

#Powershell Snapin
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

#Eventlog
    Get-EventLog System -Newest 10

#Garbage Collector
[System.GC]::Collect()

 #COM Objekte
$a = New-Object –comobject "wscript.network"
$a.username

#Credential
$Cred = Get-Credential

#Securestring
    $Password = ConvertTo-SecureString Pass@word1 -AsPlainText -Force

#Run a Script
powershell.exe "c:\myscript.ps1"

#Parameter
    myscript.ps1 server1 username
    $servername = $args[0]
    $username = $args[1]

#Function
    function sum ([int]$a,[int]$b)
    {
    $result = $a + $b
    return $result
    }
    sum 4 5

 
/*Funktion WriteLog*/
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
/*SQL Querys*/
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
$sqlReader.Read()
$Count = $sqlReader["SearchForPST"]
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

$SqlConnection.Close()
#Convert JSON
$Filetypes = Get-Content -Path E:\temp\FileTypes.json | Out-String | ConvertFrom-Json