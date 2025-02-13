Invoke-Command -ScriptBlock {
    $path = "\\ODIN\Users\Administrator\Desktop\SCCM"
    $timetablePath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowerShellScripts\Computer Lab Timetable with Classes.csv" # UNC path to timetable.csv
    $adminUsername = "PROJECT\MAdmin"
    $adminPassword = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection

    # New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $adminCredential -Persist # map network share to drive Z:\

    # get current time and today's day name
    $currentTime = Get-Date -Format "HH:mm"
    $today = Get-Date -UFormat "%A" # eg. 'Monday', 'Tuesday'

    $csvData = Import-Csv -Path $timetablePath # read CSV

    # function to process schedule for a given day
    function Get-NextClass($day) { # $day parameter can be anyday in full name format
        $sessions = $csvData | Where-Object { $_.Day -eq $day } | ForEach-Object { # gets each given day's lab start and end time 
            $timeRange = $_.Time -split "-"  # split "09:00-11:00" into ["09:00", "11:00"]
            [PSCustomObject]@{ # creates PS object to hold lab data
                StartTime = [DateTime]::ParseExact($timeRange[0], "HH:mm", $null)
                EndTime   = [DateTime]::ParseExact($timeRange[1], "HH:mm", $null)
                Lab       = $_.Lab # eg. software or network
            }
        } | Sort-Object StartTime # sort by lab's start time

        return $sessions | Where-Object { $_.Lab -ne "Break" } | Select-Object -First 1 # returns the upcoming class exlcuding breaks
    }

    $nextClass = Get-NextClass $today | Where-Object { $_.StartTime -gt (Get-Date) } # gets next scheduled class for today

    if (-not $nextClass) { # if no more classes today, find the next scheduled class on a future day
        $daysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")  # days of week to loop through
        $startIndex = $daysOfWeek.IndexOf($today) # starts the loop/array counter from today

        for ($i = 1; $i -lt $daysOfWeek.Length; $i++) { # $i = 1 to start from tomorrow's day
            $nextDay = $daysOfWeek[($startIndex + $i) % $daysOfWeek.Length] # gets the next day and wraps back around to start of array if reached the end
            $nextClass = Get-NextClass $nextDay # get lab data for "next day"
            if ($nextClass) { break } # if lab data is found then continue on to next code block otherwise keep looping through for loop until a class is found
        }
    }

    $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment # create TS variable
    if ($nextClass) { # if class found
        $nextLabType = $nextClass.Lab # stores the type of lab # eg. Network or Software
        $tsenv.Value("nextLabType") = $nextLabType # stores next lab type in TS variable
        Write-Output "Next scheduled class: $nextLabType"
        # wmic /namespace:\\root\ccm\clientsdk path CCM_TaskSequence SetVariable Name="NextLabType" Value=$nextLabType
    } else {
        Write-Output "No upcoming class found."
        # wmic /namespace:\\root\ccm\clientsdk path CCM_TaskSequence SetVariable Name="NextLabType" Value="None"
    }
}