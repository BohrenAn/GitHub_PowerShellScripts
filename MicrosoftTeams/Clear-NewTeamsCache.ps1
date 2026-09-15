###############################################################################
# Clear-NewTeamsCache.ps1
# Clear Cache of New Microsoft Teams
# V1.0 - 2026-09-15 - Initial Version - Andres Bohren
###############################################################################
# https://learn.microsoft.com/en-us/troubleshoot/microsoftteams/teams-administration/clear-teams-cache
# %userprofile%\appdata\local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams

# Close MS Teams
Write-Host "Close Microsoft Teams..."
$SessionID = (Get-Process -id $pid).SessionID
$Processes = Get-Process -name "ms-teams" | Where-Object {$_.SessionID -eq "$SessionID"}
Foreach ($Process in $Processes)
{
    Write-Host "Stopping PID: $($Process.Id)"
    Stop-Process -Id ($Process.Id) -Force
}

# Wait 3 Seconds to Close Teams
Start-Sleep -Seconds 3

# Delete Teams Cache
Write-Host "Delete Teams Cache..."
Get-ChildItem -Path "$env:LocalAppData\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams" -Recurse | Remove-Item -Recurse -Force

# Start MS Teams
Write-Host "Start Microsoft Teams"
Start-Process "ms-teams.exe"

Write-Host "Script finished... "
Read-Host "Press Enter to close"
 