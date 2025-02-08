# connect to SCCM console:
# Site configuration
Invoke-Command -ScriptBlock {
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

    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $computerName = $env:COMPUTERNAME # computer's hostname
    if ($computerName -match "MININT|WINPE") {
        $computerName = $env:SMSTSMachineName
    }
    #$computerName = "CM142-001"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    #$logFile = "$logPath\$computerName-Imaging.log" # file name to create/append
    $logFile = "$logPath\comp-Imaging.log" # file name to create/append


    # REF
    ## https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
    $collectionSearcher = Get-WmiObject -ComputerName $ProviderMachineName -Namespace root/SMS/site_$SiteCode -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$computerName' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID and CollectionID NOT LIKE 'SMS%'"
    $collectionSearcher = $collectionSearcher | Select-Object -Property Name
    $collectionList = "" # empty string to hold 'list'
    if ($collectionSearcher){ # if values found
        foreach ($collection in $collectionSearcher) { # for every collection in the list
            $collectionList += $collection.Name + ", " # append collection name to string # eg. 'name1, name2, name3'
        }
    } else { # if no values found
        $collectionList = "No collections"
    }


    # append data to log file
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # append data to file / create file if not exist
    "Imaging Attempt: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
}