#$taskSequenceName = $env:_SMSTSPackageName # gets current running TS name
Invoke-Command -ScriptBlock {
    #param ($TSName) # task sequence name
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $adminUsername = "PROJECT\MAdmin"
    $adminPassword = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection

    New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $adminCredential -Persist # map network share to drive Z:\

    $adminUserSCCM = "PROJECT\Administrator" # SCCM admin user
    $adminPassSCCM = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force # SCCM admin password
    #$adminCredSCCM = new-object -typename System.Management.Automation.PSCredential -argumentlist $adminUserSCCM,$adminPassSCCM # establishes admin credentials for connection to SCCM
    $adminCredSCCM = New-Object System.Management.Automation.PSCredential ($adminUserSCCM, $adminPassSCCM)

    $sccmSiteCode = "380" # SCCM site code 
    $SCCMServer = "odin.project.co3808.com" # SCCM FQDN

    $initParams = @{}

    # obtain MAC of client device NIC
    $MAC = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -and $_.IPEnabled }).MACAddress
    $cleanMAC = $MAC -replace ":", "-" # replaces colons with dashes to comply with Windows file names
    # $cleanMAC = "00-0C-29-1B-4E-B0"

    $macPath = "$logPath\$cleanMAC.txt" # define the MAC file location
    # retrieve the computer name based on MAC
    if (Test-Path ('FileSystem::' + $macPath)) { # match MAC with existing MAC.txt files
        $computerName = Get-Content -Path ('FileSystem::' + $macPath) # obtain computer name from matching MAC file
        Write-Host "Retrieved Computer Name: $computerName"
    } else {
        Write-Host "No Computer Name found for MAC: $cleanMAC"
        $computerName = "Unknown-PC" # no matching MAC found
    }

    # search for all user-created collections that the device is apart of
    $collectionSearcher = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace "root/SMS/site_$sccmSiteCode" `
        -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$computerName' AND SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID AND CollectionID NOT LIKE 'SMS%'"
    write-host $collectionSearcher

    if ($computerName -eq "Unknown-PC"){
        break
    } else {
        # REF
        ## https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
        # search for all user-created collections that the device is apart of
        $collectionSearcher = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace root/SMS/site_$sccmSiteCode -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$computerName' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID and CollectionID NOT LIKE 'SMS%'"
        $collectionSearcher = $collectionSearcher | Select-Object -Property Name # select colelction name field only
        $collectionList = "" # empty string to hold 'list'
        if ($collectionSearcher){ # if values found
            foreach ($collection in $collectionSearcher) { # for every collection in the list
                $collectionList += $collection.Name + ", " # append collection name to string # eg. 'collection1, collection2, collection3,'
            }
        } else { # if no values found
            $collectionList = "No collections"
        }
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    $logFile = "$logPath\$computerName-Imaging.log" # file name to create/append

    # sets task sequence variable
    $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $TSEnv.Value("imagingStart") = $timestamp # stores imaging start time in TS variable
    $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $taskSequenceName = $tsenv.Value("_SMSTSPackageName") # retrieves TS name from variable
    $taskSequenceID = $tsenv.Value("_SMSTSPackageID") # retrieves TS ID from variable


    


    # append data to log file
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # append data to file / create file if not exist
    "Imaging Start: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Computer Name: $computerName" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Task Sequence: $taskSequenceName - $taskSequenceID" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
}# -ArgumentList $taskSequenceName