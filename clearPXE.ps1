# Define paths to the CSV and scripts
$csvFilePath = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Powershell Scripts\Computer Lab Timetable.csv"
$blockPXEScriptPath = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Powershell Scripts\blockPXE.ps1"

$taskNamePrefix = "CM142Break"  # Task name prefix

# Get current time and day
$now = Get-Date
$currentDay = $now.DayOfWeek.ToString()

# Import the CSV and filter by the current day
$timeSlots = Import-Csv $csvFilePath | Where-Object { $_.Day -eq $currentDay }

# Loop through each time slot in the CSV
foreach ($slot in $timeSlots) {
    $weekPosition = $slot.WeekPosition
    $day = $slot.Day
    $time = $slot.Time
    $session = $slot.Session

    # Check if the session is a "Break"
    if ($session -eq "Break" -or [string]::IsNullOrWhiteSpace($session)) {
        # Parse time range (e.g., "10:00-10:45")
        $startTime = [datetime]::ParseExact($time.Split("-")[0].Trim(), "HH:mm", $null)
        $endTime = [datetime]::ParseExact($time.Split("-")[1].Trim(), "HH:mm", $null)
        $blockPXETime = $endTime.AddMinutes(-30)  # 30 min before break ends

        # Ensure the block time is in the future
        if ($blockPXETime -gt $now) {
            Write-Host "Scheduling BlockPXE.ps1 for $blockPXETime"

            # Create scheduled task for BlockPXE
            $blockPXEAction = New-ScheduledTaskAction -Execute "PowerShell" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$blockPXEScriptPath`""
            $blockPXETrigger = New-ScheduledTaskTrigger -Once -At $blockPXETime
            $blockPXETaskName = "$taskNamePrefix-BlockPXE-$weekPosition-$day-$startTime"

            Register-ScheduledTask -TaskName $blockPXETaskName -Action $blockPXEAction -Trigger $blockPXETrigger -TaskPath "\CM142 Lab Breaks"
        }

        # *** Clear PXE for collection ***
        Write-Host "Clearing PXE for collection..."
        Invoke-Command -ScriptBlock {
            # Press 'F5' to run this script. Running this script will load the ConfigurationManager
            # module for Windows PowerShell and will connect to the site.
            #
            # This script was auto-generated at '31/01/2025 19:38:06'.

            # Site configuration
            $SiteCode = "380" # Site code 
            $ProviderMachineName = "odin.project.co3808.com" # SMS Provider machine name

            # Customizations
            $initParams = @{}
            #$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
            #$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

            # Do not change anything below this line

            # Import the ConfigurationManager.psd1 module 
            if((Get-Module ConfigurationManager) -eq $null) {
                Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
            }

            # Connect to the site's drive if it is not already present
            if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
                New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
            }

            # Set the current location to be the site code.
            Set-Location "$($SiteCode):\" @initParams
            Get-CMDeviceCollection -Name "Disk Space Below 40G" #| Clear-CMPxeDeployment
        }
    }
}
