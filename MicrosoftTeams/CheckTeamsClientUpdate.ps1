################################################################################
# Check Microsoft Teams Client Updates
# 04.03.2022 - V1.0 - Initial Version - Andres Bohren
################################################################################

#OSX Client
$Version = "1.5.00.00000"
$Url = "https://teams.microsoft.com/package/desktopclient/update/$Version/osx/x64?ring=general"

Write-Host "Sending request to $Url"
$updateCheckResponse = Invoke-WebRequest -Uri $Url -UseBasicParsing
$updateCheckJson = $updateCheckResponse | ConvertFrom-Json
$updateCheckJson

#Windows Client
$Version = "1.5.00.4767"
$Version = "1.5.00.1870"
$Url = "https://teams.microsoft.com/desktopclient/update/$Version/windows/x64?ring=general"

Write-Host "Sending request to $Url"
$updateCheckResponse = Invoke-WebRequest -Uri $Url -UseBasicParsing
$updateCheckJson = $updateCheckResponse | ConvertFrom-Json
$updateCheckJson