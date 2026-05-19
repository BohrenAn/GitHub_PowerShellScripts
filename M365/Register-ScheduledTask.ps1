Try {
    Write-Host "Getting PowerShell Script File Information..."
    $File = Get-ChildItem -path "M365ServiceMonitor.ps1"
    $ScriptFileName = $File.Name
    $WorkingDirectory = $File.DirectoryName

    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File $ScriptFileName" -WorkingDirectory $WorkingDirectory
    $NextRun = (Get-Date).AddMinutes(15)
    $Trigger = New-ScheduledTaskTrigger -Once -At $NextRun -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
    Write-Host "Registering Scheduled Task..."
    Register-ScheduledTask -TaskName "M365ServiceMonitor" -Action $Action -Trigger $Trigger -User "SYSTEM" -RunLevel Highest
    Write-Host "Scheduled Task Registered Successfully!" -ForegroundColor Green
}
Catch {
    Write-Host "An error occurred while registering the scheduled task." -ForegroundColor Red
}