# connect to SCCM console:
# Site configuration
Invoke-Command -ScriptBlock {
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $Username = "PROJECT\MAdmin"
    $Password = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

# Map the UNC path with credentials
    New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $Credential -Persist

    $adminUserSCCM = "PROJECT\Administrator"
    $adminPassSCCM = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force
    $adminCredSCCM = new-object -typename System.Management.Automation.PSCredential -argumentlist $adminUserSCCM,$adminPassSCCM

# Ensure the path existsa
    if (!(Test-Path $logPath)) {
        #Write-Host "UNC path not accessible: $logPath"
        #Exit 1
    }

    $SiteCode = "380" # Site code 
    $ProviderMachineName = "odin.project.co3808.com" # SMS Provider machine name
    $SCCMServer = "odin.project.co3808.com"

    # Customizations
    $initParams = @{}

    # obtain MAC of device NIC
    $MAC = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -and $_.IPEnabled }).MACAddress
    $cleanMAC = $MAC -replace ":", "-" # replaces colons with dashes to comply with Windows file names

    # Define the log file location
    $macPath = "$logPath\$cleanMAC.txt"
    # retrieve the computer name based on MAC
    if (Test-Path ('FileSystem::' + $macPath)) { # match MAC with existing MAC.txt files
        $computerName = Get-Content -Path ('FileSystem::' + $macPath) # obtain computer name from matching MAC file
        Write-Host "Retrieved Computer Name: $computerName"
    } else {
        Write-Host "No Computer Name found for MAC: $cleanMAC"
        $computerName = "Unknown-PC" # no matching MAC found
    }

    $collectionSearcher = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace "root/SMS/site_$SiteCode" `
        -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$computerName' AND SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID AND CollectionID NOT LIKE 'SMS%'"
    write-host $collectionSearcher

    if ($computerName -eq "Unknown-PC"){
            break
    } else {
        # REF
        ## https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
        $collectionSearcher = Get-WmiObject -credential $adminCredSCCM -ComputerName $SCCMServer -Namespace root/SMS/site_$SiteCode -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$computerName' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID and CollectionID NOT LIKE 'SMS%'"
        $collectionSearcher = $collectionSearcher | Select-Object -Property Name
        $collectionList = "" # empty string to hold 'list'
        if ($collectionSearcher){ # if values found
            foreach ($collection in $collectionSearcher) { # for every collection in the list
                $collectionList += $collection.Name + ", " # append collection name to string # eg. 'name1, name2, name3'
            }
        } else { # if no values found
            $collectionList = "No collections"
        }
    }


    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    $logFile = "$logPath\$computerName-Imaging.log" # file name to create/append

    # append data to log file
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # append data to file / create file if not exist
    "Imaging Start: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Computer Name: $computerName" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    # "Imaging End: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    # "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
}