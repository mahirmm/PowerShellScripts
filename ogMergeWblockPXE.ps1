# Paths to the CSV  timetable file and PowerShell script
$csvFilePath = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowershellScripts\Computer Lab Timetable.csv"
$scriptPath = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowershellScripts\popup.ps1"
$removePXEScriptPath = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowershellScripts\removeFromCollection.ps1"

# Get the current day of the week
$dateTimeNow = Get-Date
$currentDay = (Get-Date).DayOfWeek.ToString()

# Import the CSV and filter by the current day
$timeSlots = Import-Csv $csvFilePath # | Where-Object { $_.Day -eq $currentDay }

# Loop through each record in csv file
foreach ($slot in $timeSlots) { # stores each field in PS variable
    $weekPosition = $slot.WeekPosition
    $day = $slot.Day
    $time = $slot.Time
    $session = $slot.Session

    # Check if the session is "Break" or empty
    if ($session -eq "Break" -or [string]::IsNullOrWhiteSpace($session)) {
        # Parse the time range (e.g., "08:00-09:00")
        $startTime = $time.Split("-")[0].Trim()
        $endDateTime = [datetime]::ParseExact($time.Split("-")[1].Trim(), "HH:mm", $null)

        # Write-Host "starttime: " $startTime
        # Write-Host "endDateTime: " $endDateTime

        # Validate time format (must be HH:mm)
        if ($startTime -match "^\d{2}:\d{2}$") {
            # Define the task name (replace ":" with "-" in the task name)
            $safeStartTime = $startTime -replace ":", "-"
            $removePXEDateTime = $endDateTime.AddMinutes(-45)  # 45 min before break ends

            # Write-Host "removepxedatetime: " $removePXEDateTime

            # trigger for task
            $taskNamePrefix = "CM142Break" # prefix to add to each task's name
            $taskName = "$taskNamePrefix-$weekPosition-$day-$safeStartTime" # title for task name eg. 'CM142-01-Monday-00-00'
            # sets task schedule to weekly on $day variable at $startTime variable
            $taskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $startTime
            $taskAction = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" # command to run PS script bypassing security policies
            # registers task in specified folder
            Register-ScheduledTask $taskName -Action $taskAction -Trigger $taskTrigger -TaskPath '\CM142 Lab Breaks'

            # Write-Host "Scheduling BlockPXE.ps1 for $removePXEDateTime"

            # Create scheduled task for BlockPXE
            $removePXETime = $removePXEDateTime.ToString("HH:mm")
            $removePXETrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $removePXETime
            $removePXEAction = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$removePXEScriptPath`""
            $removePXETaskName = "$taskNamePrefix-RemovePXE-$weekPosition-$day-$safeStartTime"

            Register-ScheduledTask $removePXETaskName -Action $removePXEAction -Trigger $removePXETrigger -TaskPath "\CM142 Lab Breaks"
            
        }
    }
}



        # # Ensure the block time is in the future
        