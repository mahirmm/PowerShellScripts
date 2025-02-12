#$taskSequenceName = $env:_SMSTSPackageName # gets current running TS name
Invoke-Command -ScriptBlock {
    #param ($TSName) # task sequence name
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $adminUsername = "PROJECT\MAdmin"
    $adminPassword = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $adminCredential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword) # establishes admin credentials for connection

    # New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $adminCredential -Persist # map network share to drive Z:\

    $adminUserSCCM = "PROJECT\Administrator" # SCCM admin user
    $adminPassSCCM = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force # SCCM admin password
    $adminCredSCCM = New-Object System.Management.Automation.PSCredential ($adminUserSCCM, $adminPassSCCM)

    $sccmSiteCode = "380" # SCCM site code 
    $SCCMServer = "odin.project.co3808.com" # SCCM FQDN

    $initParams = @{}

    $computerName = "CM142-004"

    # search for all user-created collections that the device is apart of
    #$collectionSearcher = Get-WmiObject -ComputerName $SCCMServer -Namespace "root/SMS/site_$sccmSiteCode" `
     #   -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$computerName' AND SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID AND CollectionID NOT LIKE 'SMS%'"
    #write-host $collectionSearcher

    if ($computerName -eq "Unknown-PC"){
    } else {
        # REF
        ## https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
        # search for all user-created collections that the device is apart of
        $collectionSearcher = Get-WmiObject -ComputerName $SCCMServer -Namespace root/SMS/site_$sccmSiteCode -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$computerName' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID and CollectionID NOT LIKE 'SMS%'"
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



    # search for all user-created collections that the device is apart of
    $collectionSearcher = Get-WmiObject -ComputerName $SCCMServer -Namespace "root/SMS/site_$sccmSiteCode" `
        -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$computerName' AND SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID AND CollectionID NOT LIKE 'SMS%'" |
        Select-Object -ExpandProperty Name
    $collectionSearcher = ($collectionSearcher -join ', ') # seperate with comma and a space
    write-host $collectionSearcher

    $TSname = 'Deploy OS'

    # checks which collections contains the "Deploy OS" task sequence
    $TSquery = Get-WmiObject -ComputerName $SCCMServer -Namespace root/SMS/site_$sccmSiteCode -Query `
        "SELECT CollectionID, CollectionName, PackageID, PackageName FROM SMS_AdvertisementInfo WHERE CollectionID NOT LIKE 'SMS%' and PackageName = 'Deploy OS'" |
        Select-Object -ExpandProperty CollectionName
    write-host $TSquery


    $cautionCollections = "Disk Space Below 40G", "NoRustDesk" # list of collections that could initiate an automatic collection
    $collectionSearcherArray = $collectionSearcher -split ", " # convert collectionSearcher into indexable array
    $exists = $cautionCollections | Where-Object { $collectionSearcherArray -contains $_ } # compares two arrays to find macthes
    $exists = ($exists -join ', ') # join list of matching collections
    if ($exists) {
        Write-Output "Device reimaged with $TSname as it is in collection(s) $exists"
    } else {
        Write-Output "Unable to determine device reimage reason"
    }





    # $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    # $logFile = "$logPath\$computerName-OSDReason-Imaging.log" # file name to create/append

    # sets task sequence variable
    # $TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    # $TSEnv.Value("imagingStart") = $timestamp
    # $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    # $taskSequenceName = $tsenv.Value("_SMSTSPackageName")


    # append data to log file
    # "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # append data to file / create file if not exist
    # "Imaging Start: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    # "Computer Name: $computerName" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    # "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    # "Task Sequence: $taskSequenceName" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
}