###############################################################################
# Get Exchange AD Schema Version
# 23.02.2023 - Initial Version - Andres Bohren
###############################################################################
#Needs ActiveDirectory PowerShell Module

# Exchange Schema Version
$sc = (Get-ADRootDSE).SchemaNamingContext
$ob = "CN=ms-Exch-Schema-Version-Pt," + $sc
Write-Output "RangeUpper: $((Get-ADObject $ob -pr rangeUpper).rangeUpper)"

# Exchange Object Version (domain)
$dc = (Get-ADRootDSE).DefaultNamingContext
$ob = "CN=Microsoft Exchange System Objects," + $dc
Write-Output "ObjectVersion (Default): $((Get-ADObject $ob -pr objectVersion).objectVersion)"

# Exchange Object Version (forest)
$cc = (Get-ADRootDSE).ConfigurationNamingContext
$fl = "(objectClass=msExchOrganizationContainer)"
Write-Output "ObjectVersion (Configuration): $((Get-ADObject -LDAPFilter $fl -SearchBase $cc -pr objectVersion).objectVersion)"