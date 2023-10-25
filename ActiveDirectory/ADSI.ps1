###############################################################################
# ADSI - Active Directory Service Interface
# 2023.10.23 - Initial Version - Andres Bohren
###############################################################################
$Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher

# Limit the output to 50 objects
$Searcher.SizeLimit = '5000'

$DomainArray = @() 
$DomainArray += "DC=corp,DC=icewolf,DC=ch"

Foreach ($Domain in $DomainArray)
{
	$ADResult = @()

	#Search Root
	#$Searcher.SearchRoot = "LDAP://DC=corp,DC=icewolf,DC=ch"
	$Searcher.SearchRoot = "LDAP://$Domain"
	Write-Host "Working on: $($Searcher.SearchRoot.distinguishedName)" -ForegroundColor Cyan

	#Prepare CSV File
	Set-Content -Path C:\Temp\ADOverview.csv -Value ("Domain;UserCount;ContactCount;GroupCount;ComputerCount")

	###############################################################################
	# Get only the User objects
	###############################################################################
	$Searcher.Filter = "(&(objectClass=user)(objectCategory=person))"

	# Execute the Search
	$ADResult = $Searcher.FindAll()
	$UserCount = $ADResult.Count
	Write-Host "Users: $($ADResult.Count)" -ForegroundColor Green

	###############################################################################
	# Get only the Contact objects
	###############################################################################
	$Searcher.Filter = "(objectClass=contact)"

	# Execute the Search
	$ADResult = $Searcher.FindAll()
	$ContactCount = $ADResult.Count
	Write-Host "Contact: $($ADResult.Count)" -ForegroundColor Green

	###############################################################################
	# Get only the Groups
	###############################################################################
	$Searcher.Filter = "(objectClass=group)"

	# Execute the Search
	$ADResult = $Searcher.FindAll()
	$GroupCount = $ADResult.Count
	Write-Host "Group: $($ADResult.Count)" -ForegroundColor Green

	###############################################################################
	# Get only the Computer objects
	###############################################################################
	$Searcher.Filter = "(objectClass=computer)"

	# Execute the Search
	$ADResult = $Searcher.FindAll()
	$ComputerCount = $ADResult.Count
	Write-Host "Computer: $($ADResult.Count)" -ForegroundColor Green

	Add-Content -Path C:\Temp\ADOverview.csv -Value ("$Domain;$UserCount;$ContactCount;$GroupCount;$ComputerCount")
}

