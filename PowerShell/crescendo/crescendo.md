Microsoft.PowerShell.Crescendo overview
https://learn.microsoft.com/en-us/powershell/utility-modules/crescendo/overview?view=ps-modules

Install the Crescendo module
https://learn.microsoft.com/en-us/powershell/utility-modules/crescendo/get-started/install-crescendo?view=ps-modules

Install-Module Microsoft.PowerShell.Crescendo -AllowPreview



$parameters = @{
    Verb = 'Get'
    Noun = 'Ipconfig'
    OriginalName = 'C:\Windows\System32\ipconfig.exe'
}
New-CrescendoCommand @parameters | Format-List *


New-Item -Path "c:\temp" -Name "Ipconfig" -ItemType "directory"
$CrescendoCommands = New-CrescendoCommand @parameters
Export-CrescendoCommand -command $CrescendoCommands -targetDirectory C:\Temp\Ipconfig
Get-ChildItem -Path C:\Temp\Ipconfig


Export-CrescendoModule -ConfigurationFile C:\Temp\Ipconfig\Get-Ipconfig.crescendo.json -ModuleName C:\Temp\Ipconfig\Ipconfig.psm1 -Force
Get-ChildItem -Path C:\Temp\Ipconfig

New-CrescendoCommand -Verb Get -Noun Ipconfig -OriginalName "ipconfig.exe" | ConvertTo-Json

{
  "Verb": "Get",
  "Noun": "Something",
  "OriginalName": "native.exe",
  "OriginalCommandElements": null,
  "Platform": [
    "Windows",
    "Linux",
    "MacOS"
  ],
  "Elevation": null,
  "Aliases": null,
  "DefaultParameterSetName": null,
  "SupportsShouldProcess": false,
  "ConfirmImpact": null,
  "SupportsTransactions": false,
  "NoInvocation": false,
  "Description": null,
  "Usage": null,
  "Parameters": [],
  "Examples": [],
  "OriginalText": null,
  "HelpLinks": null,
  "OutputHandlers": null,
  "FunctionName": "Get-Something"
}