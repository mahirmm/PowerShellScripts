# connect to SCCM console:
# Site configuration
Invoke-Command -ScriptBlock {
    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
# Manually authenticate (replace with a valid domain user)
    $Username = "PROJECT\MAdmin"
    $Password = ConvertTo-SecureString "Shaolin1" -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

# Map the UNC path with credentials
    New-PSDrive -Name Z -PSProvider FileSystem -Root $logPath -Credential $Credential -Persist

# Ensure the path existsa
    if (!(Test-Path $logPath)) {
        #Write-Host "UNC path not accessible: $logPath"
        #Exit 1
    }

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

    $MACreal = (Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -and $_.IPEnabled }).MACAddress
    $MAC = "00:0C:29:1B:4E:B0"
    $cleanMAC = $MAC -replace ":", "-" # replaces colons with dashes to comply with Windows file names

    # Define the log file location
    $macPath = "$logPath\$cleanMAC.txt"
# Retrieve the computer name
    if (Test-Path ('FileSystem::' + $macPath)) {
        $computerName = Get-Content -Path ('FileSystem::' + $macPath)
        Write-Host "Retrieved Computer Name: $computerName"
    } else {
        Write-Host "No Computer Name found for MAC: $cleanMAC"
        $computerName = "Unknown-PC"
    }


    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    #$logFile = "$logPath\$computerName-Imaging.log" # file name to create/append
    $logFile = "$logPath\TS-Imaging.log" # file name to create/append

    if ($computerName -eq "Unknown-PC"){
        break
    } else {
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
    }


    # append data to log file
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # append data to file / create file if not exist
    "Imaging Attempt: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "computername: $computerName" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "MACreal: $MACreal" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
}