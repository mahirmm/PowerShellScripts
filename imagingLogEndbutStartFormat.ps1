Invoke-Command -ScriptBlock {
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $adminUsername = "PROJECT\MAdmin"
    $adminPassword = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection

    New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $adminCredential -Persist # map network share to drive Z:\

    # $adminUserSCCM = "PROJECT\Administrator" # SCCM admin user
    # $adminPassSCCM = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force # SCCM admin password
    # #$adminCredSCCM = new-object -typename System.Management.Automation.PSCredential -argumentlist $adminUserSCCM,$adminPassSCCM # establishes admin credentials for connection to SCCM
    # $adminCredSCCM = New-Object System.Management.Automation.PSCredential ($adminUserSCCM, $adminPassSCCM)

    $sccmSiteCode = "380" # SCCM site code 
    $SCCMServer = "odin.project.co3808.com" # SCCM FQDN
    $computerName = $env:COMPUTERNAME # computer name/hostname

    $initParams = @{}

    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    $logFile = "$logPath\$computerName-Imaging.log" # file name to create/append

    # retrieve task sequence variable
    $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $imagingStartTS = $TSEnv.Value("imagingStart") # time TS started
    $imagingStart = [datetime]$imagingStartTS # convert to date time
    $imagingEnd = [datetime]$timestamp # time TS ended in date time

    $imagingTimeDifference = $imagingEnd - $imagingStart # time difference in HH:mm:ss
    # $imagingHours = ([math]::Round($($imagingTimeDifference.TotalHours))) # hours imaging rounded to 1 decimal place
    # $imagingMinutes = $imagingTimeDifference.Minutes # minutes imaging
    # $imagingSeconds = $imagingTimeDifference.Seconds # seconds imaging
    # $imagingDuration = $imagingHours + "hours" + $imagingMinutes + "minutes and" + $imagingSeconds + "seconds"

    "Imaging End: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Imaging Duration: $imagingTimeDifference" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    # "Imaging Duration: $imagingDuration" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
} #-ArgumentList $taskSequenceName