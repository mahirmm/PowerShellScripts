# below script was created by SCCM console to connect PowerShell to SCCM site
# This script was auto-generated at '31/01/2025 19:38:06'.
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

    $includeCollectionName = "Disk Space Below 40G" # collection 'included' in below collection
    $collectionName = "Automatic OS Deployment" # collection to run command against
    $collectionID = "3800001A" # above collection but ID
    Get-CMCollection -Name $collectionName | Add-CMDeviceCollectionIncludeMembershipRule -IncludeCollectionName $includeCollectionName # add collection to collection
    Start-Sleep -Seconds 5 # delay for 5s to allow collection membership to update
    Get-CMCollection -Name $collectionName | Invoke-CMCollectionUpdate # update collection membership rules

    $timeout = 300 # 5 minute timeout
    $timeElapsed = 0 # seconds counter

    do { # check if membership rules updated successfully
        Start-Sleep -Seconds 10
        $timeElapsed += 10 # increase counter by 10seconds
        $collectionDevices = Get-CMDevice -CollectionName $collectionName

        if ($collectionDevices.Count -gt 0) { # if there is more than 1 device in the collection ...
            break # exit loop as collection has begun to update membership rules
        }
    } while ($timeElapsed -lt $timeout) # loop until 5 minutes elapsed

    $collectionDevices = Get-CMDevice -CollectionName $collectionName # obtain all devices in the collection
    foreach ($device in $collectionDevices) { # loop through each device and clear PXE deployment
        Clear-CMPxeDeployment -ResourceId $device.ResourceID # clears device's PXE flag using the device's resourceID
        Write-Host "PXE Cleared"
    }
    $clientRestarter = "C:\Users\Administrator\Desktop\SCCM\SCCM Boot Images\PowershellScripts\clientRestarter.ps1"
    & $clientRestarter

}