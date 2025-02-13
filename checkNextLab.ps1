Invoke-Command -ScriptBlock {
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\Logs" # UNC path to log folder
    $timetablePath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowerShellScripts\Computer Lab Timetable with Classes.csv" # UNC path to timetable.csv
    $adminUsername = "PROJECT\MAdmin"
    $adminPassword = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection

    New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $adminCredential -Persist # map network share to drive Z:\

    $today = Get-Date -Format "dddd" # get today's day name # eg. 'Monday', 'Tuesday'
    $currentTime = Get-Date -Format "HH:mm" # get current time 
    $csvData = Import-Csv -Path $timetablePath # read CSV

    # function to process schedule for a given day
    ## $day parameter can be anyday in full name format
    ## $ignoreTimeCheck parameter is used when checking future days' schedules
    function Get-NextClass($day, $ignoreTimeCheck = $false) {
        $sessions = $csvData | Where-Object { $_.Day -eq $day } | ForEach-Object { # gets each given day's lab start and end time 
            $timeRange = $_.Time -split "-"  # split "09:00-11:00" into ["09:00", "11:00"]
            [PSCustomObject]@{ # creates PS object to hold lab data
                StartTime = [DateTime]::ParseExact($timeRange[0], "HH:mm", $null)
                EndTime   = [DateTime]::ParseExact($timeRange[1], "HH:mm", $null)
                Lab       = $_.Lab # eg. software or network
            }
        } | Sort-Object StartTime # sort by lab's start time

        if (-not $ignoreTimeCheck) { # if checking today, ignore past classes
            $sessions = $sessions | Where-Object { $_.StartTime -gt [DateTime]::ParseExact($currentTime, "HH:mm", $null) }
        }
        return $sessions | Where-Object { $_.Lab -ne "Break" } | Select-Object -First 1 # return next available lab that is not a break session
    }

    $nextClass = Get-NextClass $today # find today's next class

    if (-not $nextClass) { # if no more classes today, find the next scheduled class on a future day
        $daysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday") # days of week to loop through
        $startIndex = $daysOfWeek.IndexOf($today) # starts the loop/array counter from today

        for ($i = 1; $i -lt $daysOfWeek.Length; $i++) { # $i = 1 to start from tomorrow's day
            $nextDay = $daysOfWeek[($startIndex + $i) % $daysOfWeek.Length]# gets the next day and wraps back around to start of array if reached the end
            $nextClass = Get-NextClass $nextDay -ignoreTimeCheck $true # get lab data for "next day" ignoring time filtering
            if ($nextClass) { break } # if lab data is found then continue on to next code block otherwise keep looping through for loop until a class is found
        }
    }

    $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment # initialise TS variable
    if ($nextClass) { # when lab found
        $nextLabType = $nextClass.Lab # store lab details in variable
        $tsenv.Value("nextLabType") = $nextLabType # store lab details in TS variable
        Write-Output "Next scheduled class: $nextLabType"
    } else { # no lab found
        Write-Output "No upcoming class found."
        $tsenv.Value("nextLabType") = "None" # revert to default TS settings
    }
}
