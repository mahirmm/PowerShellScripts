# Paths to the CSV  timetable file and PowerShell script
$csvFilePath = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Powershell Scripts\Computer Lab Timetable.csv"
$scriptPath = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Powershell Scripts\popup.ps1"


$taskNamePrefix = "CM142Break" # prefix to add to each task's name
$taskAction = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" # command to run PS script bypassing security policies

# Get the current day of the week
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

        # Validate time format (must be HH:mm)
        if ($startTime -match "^\d{2}:\d{2}$") {
            # Define the task name (replace ":" with "-" in the task name)
            $safeStartTime = $startTime -replace ":", "-"
            $taskName = "$taskNamePrefix-$weekPosition-$day-$safeStartTime" # title for task name eg. 'CM142-01-Monday-00-00'

            # testing variables
            Write-Warning "$startTime"
            Write-Warning "$day"

            # trigger for task
            # sets task schedule to weekly on $day variable at $startTime variable
            $taskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $startTime

            # registers task in specified folder
            Register-ScheduledTask $taskName -Action $taskAction -Trigger $taskTrigger -TaskPath '\CM142 Lab Breaks'
        }
    }
}