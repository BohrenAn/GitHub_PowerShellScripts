###############################################################################
# Get ms-teams.exe Processes for current user and all its Sub-Processes
# Summarize all the Memory used
# 2026-09-06 - Initial Version - Andres Bohren
###############################################################################

# Get current user
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

# Get all processes
$allProcesses = Get-CimInstance Win32_Process

# Teams root processes
$teamsProcesses = $allProcesses | Where-Object {
    $_.Name -match '^(ms-teams|teams)\.exe$'
}

if (-not $teamsProcesses) {
    Write-Host "No Microsoft Teams process found." -ForegroundColor Yellow
    return
}

# Function to get all child processes recursively
function Get-ChildProcesses {
    param (
        [int[]]$ParentProcessIds,
        $AllProcesses
    )

    $children = $AllProcesses | Where-Object {
        $_.ParentProcessId -in $ParentProcessIds
    }

    if ($children) {
        $grandChildren = Get-ChildProcesses `
            -ParentProcessIds $children.ProcessId `
            -AllProcesses $AllProcesses

        return $children + $grandChildren
    }

    return $children
}

# Collect Teams processes and descendants
$teamsTree = foreach ($teams in $teamsProcesses) {
    $children = Get-ChildProcesses `
        -ParentProcessIds $teams.ProcessId `
        -AllProcesses $allProcesses

    $teams
    $children
}

# Remove duplicates
$teamsTree = $teamsTree | Sort-Object ProcessId -Unique

# Retrieve process owner and memory information
$result = foreach ($proc in $teamsTree) {
    try {
        $ownerInfo = Invoke-CimMethod -InputObject $proc -MethodName GetOwner -ErrorAction Stop
        $owner = "$($ownerInfo.Domain)\$($ownerInfo.User)"

        if ($owner -ieq $currentUser) {
            $psProc = Get-Process -Id $proc.ProcessId -ErrorAction SilentlyContinue

            if ($psProc) {
                [PSCustomObject]@{
                    ProcessName = $proc.Name
                    PID         = $proc.ProcessId
                    MemoryMB    = [Math]::Round($psProc.WorkingSet64 / 1MB, 2)
                }
            }
        }
    }
    catch {
        # Ignore processes where owner cannot be determined
    }
}

# Display details
$result | Sort-Object MemoryMB -Descending | Format-Table -AutoSize

# Summary
$totalMemoryMB = ($result | Measure-Object MemoryMB -Sum).Sum

Write-Host ""
Write-Host "Teams Total Memory Usage (Current User): $([Math]::Round($totalMemoryMB,2)) MB" -ForegroundColor Green