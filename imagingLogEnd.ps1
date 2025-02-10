$sccmSiteCode = "380" # SCCM site code 
$SCCMServer = "odin.project.co3808.com" # SCCM FQDN
$adminUsername = "PROJECT\administrator"
$adminPassword = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force
$adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection to SCCM
$computerName = $env:COMPUTERNAME # computer name/hostname

$Session = New-PSSession -ComputerName $SCCMServer -Credential $adminCredential # establish connection to SCCM server

Invoke-Command -Session $Session -ScriptBlock {
    param ($sccmSiteCode, $SCCMServer, $computerName)

    Import-Module ($ENV:SMS_ADMIN_UI_PATH + "\..\ConfigurationManager.psd1") -ErrorAction Stop
    Set-Location "$sccmSiteCode`:"

    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    $logFile = "$logPath\$computerName-Imaging.log" # file name to create/append

    "Imaging End: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append

} -ArgumentList $sccmSiteCode, $SCCMServer, $computerName

Remove-PSSession $Session