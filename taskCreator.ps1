# Paths to the CSV  timetable file and PowerShell script
$CM142Timetable = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowershellScripts\Computer Lab Timetable.csv" # cm142 timetable csv
$addToSCCMCollection = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowershellScripts\addToCollection.ps1" # script adds devices to SCCM collection
$removeFromSCCMCollection = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowershellScripts\removeFromCollection.ps1" # script removes devices from SCCM collection

$currentDay = (Get-Date).DayOfWeek.ToString() # current day of week
$timeSlots = Import-Csv $CM142Timetable # Import CSV timetable file

# Loop through each record in CSV file
foreach ($slot in $timeSlots) { # stores each field in PS variables
    $weekPosition = $slot.WeekPosition # eg '01'
    $day = $slot.Day # eg 'Monday'
    $time = $slot.Time # eg '00:00-9:00'
    $session = $slot.Session # eg 'Break'
    $classNum = $slot.ClassNum # eg '006'

    # Check if the session is "Break" or empty
    if ($session -eq "Break" -or [string]::IsNullOrWhiteSpace($session)) {
        # extract the time ranges
        $startTime = $time.Split("-")[0].Trim() # start time of each break
        $endDateTime = [datetime]::ParseExact($time.Split("-")[1].Trim(), "HH:mm", $null) # endtime of each break - needs to be in datetime format for mathematical operations
        $removePXEDateTime = $endDateTime.AddMinutes(-45)  # 45 min before break ends

        # Create scheduled task to add devices to SCCM collection and initiate reimaging
        $taskNamePrefix = "CM142Break" # prefix to add to each task's name
        $addToCollTaskName = "$taskNamePrefix-$weekPosition-$day-$classNum" # title for task name eg. 'CM142-01-Monday-00-00'
        $addToCollTaskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $startTime # sets task schedule to weekly on $day variable at $startTime variable
        $addToCollTaskAction = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$addToSCCMCollection`"" # command to run PS script bypassing security policies
        Register-ScheduledTask $addToCollTaskName -Action $addToCollTaskAction -Trigger $addToCollTaskTrigger -TaskPath '\CM142 Lab Breaks' # registers task in specified folder

        # Create scheduled task to remove devices from SCCM collection and stop new reimaging attempts
        $removePXETime = $removePXEDateTime.ToString("HH:mm") # convert date time value back to time only
        $removePXETaskName = "$taskNamePrefix-RemoveCollection-$weekPosition-$day-$classNum" # title for task name eg. 'CM142-RemoveCollection-01-Monday-00-00'
        $removePXETrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $removePXETime # sets task schedule to weekly on $day variable at $removePXETime variable
        $removePXEAction = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$removeFromSCCMCollection`"" # command to run PS script bypassing security policies
        Register-ScheduledTask $removePXETaskName -Action $removePXEAction -Trigger $removePXETrigger -TaskPath "\CM142 Lab Breaks" # registers task in specified folder
    }
}
        