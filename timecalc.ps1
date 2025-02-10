

# Query WMI for the currently running Task Sequence



Invoke-Command -ScriptBlock {
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $adminUsername = "PROJECT\MAdmin"
    $adminPassword = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection

    #New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $adminCredential -Persist # map network share to drive Z:\

    $adminUserSCCM = "PROJECT\Administrator" # SCCM admin user
    $adminPassSCCM = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force # SCCM admin password
    $adminCredSCCM = new-object -typename System.Management.Automation.PSCredential -argumentlist $adminUserSCCM,$adminPassSCCM # establishes admin credentials for connection to SCCM
    $sccmSiteCode = "380" # SCCM site code 
    $SCCMServer = "odin.project.co3808.com" # SCCM FQDN
    $SCCMServer = "odin.project.co3808.com" # Replace with your SCCM server name
    $SiteCode = "380" # Your SCCM Site Code
    $ComputerName = "CM142-001" # Replace with the device name

    $initParams = @{}


    # search for all user-created collections that the device is apart of
     #$collectionSearcher = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace "root/SMS/site_$sccmSiteCode" `
      #   -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$computerName' AND SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID AND CollectionID NOT LIKE 'SMS%'"
    #$deployment = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace "root/SMS/site_$sccmSiteCode" ` | 
    #    Where-Object { $_.MachineName -eq $ComputerName } | 
    #    Select-Object MachineName, DeploymentID, LastActiveTime, LastStatusMsgID, StartTime, EndTime
    $deployment = Get-WmiObject -Namespace "root\SMS\site_$SiteCode" -Class "SMS_TSExecutionHistory" -ComputerName $SCCMServer |
    Where-Object { $_.MachineName -eq $ComputerName } | 
    Select-Object MachineName, AdvertisementID, PackageID, ProgramName, StartTime, EndTime

    write-host $deployment
}