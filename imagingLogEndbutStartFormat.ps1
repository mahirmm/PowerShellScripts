# script to determine:
## hostname of current computer
## SCCM collections of current computer
## current TS deployment
## TS deployment reason
### all details saved to "[hostname]-Imaging.log"

Invoke-Command -ScriptBlock {
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $adminUsername = "PROJECT\MAdmin"
    $adminPassword = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection

    New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $adminCredential -Persist # map network share to drive Z:\

    $sccmSiteCode = "380" # SCCM site code 
    $SCCMServer = "odin.project.co3808.com" # SCCM FQDN
    $computerName = $env:COMPUTERNAME # get computer name/hostname by querying SCCM/OS

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

    "Imaging End: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # time TS completed
    "Imaging Duration: $imagingTimeDifference" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # duration of imaging
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # seperator
}