# client mac finsher

$SCCMServer = "odin.project.co3808.com"
$SiteCode = "380"
$Username = "PROJECT\administrator"
$Password = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
$computerName = $env:COMPUTERNAME

$Session = New-PSSession -ComputerName $SCCMServer -Credential $Credential

Invoke-Command -Session $Session -ScriptBlock {
    param ($SiteCode, $SCCMServer, $computerName)

    Import-Module ($ENV:SMS_ADMIN_UI_PATH + "\..\ConfigurationManager.psd1") -ErrorAction Stop
    Set-Location "$SiteCode`:"

    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    $logFile = "$logPath\$computerName-Imaging.log" # file name to create/append

    # "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Imaging End: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append

} -ArgumentList $SiteCode, $SCCMServer, $computerName

Remove-PSSession $Session
