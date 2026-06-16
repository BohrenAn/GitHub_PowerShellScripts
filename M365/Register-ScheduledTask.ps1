###############################################################################
# Register-ScheduledTask.ps1
# V1.0 - 2026-06-13 - Initial Version - Andres Bohren
###############################################################################
#Requires -RunAsAdministrator

Try {
    Write-Host "Getting PowerShell Script File Information..."
    $File = Get-ChildItem -path "M365ServiceMonitor.ps1"
    $ScriptFileName = $File.FullName
    #$WorkingDirectory = $File.DirectoryName

    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File $ScriptFileName" #-WorkingDirectory $WorkingDirectory
    $NextRun = (Get-Date).AddMinutes(15)
    $RepetitionInterval = New-TimeSpan -Minutes 15
    $RepetitionDuration = New-TimeSpan -Days 3650 #10 years
    $Trigger = New-ScheduledTaskTrigger -Once -At $NextRun -RepetitionInterval $RepetitionInterval -RepetitionDuration $RepetitionDuration
    Write-Host "Registering Scheduled Task..."
    Register-ScheduledTask -TaskName "M365ServiceMonitor" -Action $Action -Trigger $Trigger -User "SYSTEM" #-RunLevel Highest
    Write-Host "Scheduled Task Registered Successfully!" -ForegroundColor Green
    Write-Host "Run 'taskschd.msc' as Administrator to view the task." -ForegroundColor Green


}
Catch {
    Write-Host "An error occurred while registering the scheduled task." -ForegroundColor Red
}