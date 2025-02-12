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

    $adminUserSCCM = "PROJECT\Administrator" # SCCM admin user
    $adminPassSCCM = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force # SCCM admin password
    $adminCredSCCM = New-Object System.Management.Automation.PSCredential ($adminUserSCCM, $adminPassSCCM) # establishes admin credentials for connection to SCCM

    $sccmSiteCode = "380" # SCCM site code 
    $SCCMServer = "odin.project.co3808.com" # SCCM FQDN

    $initParams = @{}

    # obtain MAC of client device NIC
    $MAC = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -and $_.IPEnabled }).MACAddress
    $cleanMAC = $MAC -replace ":", "-" # replaces colons with dashes to comply with Windows file names

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

    # search for all user-created collections that the device is apart of
    $collectionSearcher = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace "root/SMS/site_$sccmSiteCode" `
        -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$computerName' AND SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID AND CollectionID NOT LIKE 'SMS%'" |
        Select-Object -ExpandProperty Name # selects name field only
    $collectionSearcher = ($collectionSearcher -join ', ') # seperate with comma and a space
    write-host $collectionSearcher

    # checks which collections contains the "$taskSequenceName" task sequence
    $TSquery = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace root/SMS/site_$sccmSiteCode -Query `
        "SELECT CollectionID, CollectionName, PackageID, PackageName FROM SMS_AdvertisementInfo WHERE CollectionID NOT LIKE 'SMS%' and PackageName = '$taskSequenceName'" |
        Select-Object -ExpandProperty CollectionName
    write-host $TSquery

    $cautionCollections = "Disk Space Below 40G", "NoRustDesk" # list of collections that could initiate an automatic collection
    $collectionSearcherArray = $collectionSearcher -split ", " # convert collectionSearcher into indexable array
    $exists = $cautionCollections | Where-Object { $collectionSearcherArray -contains $_ } # compares two arrays to find macthes
    $exists = ($exists -join ', ') # join list of matching collections
    if ($exists) { # if match found
        $deploymentReason = "Device reimaged with $taskSequenceName as it is in collection(s) $exists"
    } else { # no match found
        $deploymentReason = "Unable to determine device reimage reason"
    }

     # append data to log file / create file if not exist
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # seperator
    "Imaging Start: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # time TS started
    "Computer Name: $computerName" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # hostname
    "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # list of user-created collections
    "Task Sequence (Name - ID): $taskSequenceName - $taskSequenceID" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # TS name and ID
    "Deployment Reason: $deploymentReason" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # why the computer reimaged
}