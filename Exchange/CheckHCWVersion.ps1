###############################################################################
# CheckHCWVersion.ps1
# Downloads Exchange Online Hybrid Configuration Wizard (HCW) and checks
# Version against stored Version in TXT File
# 14.07.2025 - V1.0 - Initial Code - Andres Bohren 
# 06.04.2026 - V1.1 - Updated URL and addet -UseBasicParsing - Andres Bohren
###############################################################################
$HCWFile = "E:\Scripts\Microsoft.Online.CSE.Hybrid.Client.application"
$From = "Administrator@icewolf.ch"
$To = "a.bohren@icewolf.ch"
$SMTPServer = "172.21.175.21"

#Download HCW
#QRecord: hybridconfigwizard.azurewebsites.net of type Host Addr on class Internet
#$URL = "https://shcwreleaseprod.blob.core.windows.net/shcw/Microsoft.Online.CSE.Hybrid.Client.application"
#$URL = "https://hybridconfiguration.blob.core.windows.net/shcw/Microsoft.Online.CSE.Hybrid.Client.application"
$URL = "https://hybridconfigwizard.azurewebsites.net/ClickOnce/Microsoft.Online.CSE.Hybrid.Client.application"
Invoke-WebRequest -Method GET -Uri $URL -OutFile $HCWFile -UseBasicParsing

#Load XML
[XML]$XML = Get-Content -Path $HCWFile

#Get HCW Version
$HCWVersion = $xml.assembly.assemblyIdentity.version
Write-Host "HCWVersion: $HCWVersion" -ForegroundColor Cyan

If ((Test-Path -Path ".\HCWVersion.txt") -eq $false)
{
    #HCWVersion.txt does not exist
    $StoredHCWVersion = "0"
} else {
    $StoredHCWVersion = Get-Content -Path ".\HCWVersion.txt"
}
Write-Host "StoredHCWVersion: $StoredHCWVersion" -ForegroundColor Cyan
Set-Content ".\HCWVersion.txt" -Value $HCWVersion

If ($HCWVersion -ne $StoredHCWVersion)
{
    #Versions are diffrent
    $sendMailMessageSplat = @{
    From = $From
    To = $To
    Subject = "HCW Version Test"
    Body = "StoredVersion: $StoredHCWVersion`r`nHCWVersion: $HCWVersion"
    SmtpServer = $SMTPServer
    }
    Write-Host "Diffrent Versions: Send Mail" -ForegroundColor Cyan
    Send-MailMessage @sendMailMessageSplat
}
