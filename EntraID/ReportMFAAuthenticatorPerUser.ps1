###############################################################################
# Check MFA Microsoft Authenticator per User
# 20.02.2025 V0.1 - Initial Version - Andres Bohren
###############################################################################

#Connect to Microsoft Graph
Connect-MgGraph -Scopes UserAuthenticationMethod.Read.All -NoWelcome

#Create Collection of UPN
$UPNCollection = [System.Collections.Generic.List[string]]::new()
$UPNCollection.Add("m.muster@icewolf.ch")
$UPNCollection.Add("e.muster@icewolf.ch")
$UPNCollection.Add("postmaster@icewolf.ch")
$UPNCollection.Add("a.bohren@icewolf.ch")

#CSV Import
$UPNCollection = [System.Collections.Generic.List[string]]::new()
$CSV = Import-CSV -Path "C:\Temp\UPN.csv"
Foreach ($Row in $CSV)
{
	$UPNCollection.Add($Row.UPN)
}

#Loop through UPN
Foreach ($UPN in $UPNCollection)
{
    $AuthMethods = Get-MgUserAuthenticationMethod -UserId $UPN
    [array]$Authenticator = $AuthMethods | Where-Object {$_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"}
    if ($Null -eq $Authenticator)
    {
        Write-Host "$UPN > NO MFA" -ForegroundColor Cyan
    } else {
        Write-Host "$UPN > MFA found" -ForegroundColor Green
    }
}