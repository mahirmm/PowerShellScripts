# below script was created by SCCM console to connect PowerShell to SCCM site
# This script was auto-generated at '31/01/2025 19:38:06'.

# Site configuration
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

$collectionName = "Automatic OS Deployment" # collection to run command against
$collectionDevices = Get-CMDevice -CollectionName $collectionName # obtains device info on all devices in the colelction
$deviceList = @() # creates empty array
$numberOfDevicesinCollection = $collectionDevices.Count # counts number of devices in colelction
$numberOfDevicesinList = 1 # counts number of devices in array/list - starts at 1 to account for last value of array
foreach ($device in $collectionDevices) { # for every device in the collection
    if ($numberOfDevicesinList -lt $numberOfDevicesinCollection){
        $deviceList += $device.Name #+ ',' # append device name and comma seperator to array 'name1, name2, name3'
        $numberOfDevicesinList += 1
    } else {
        $deviceList += $device.Name # only appends name and no comma as this is the last value of the array
    }
}

Restart-Computer -ComputerName $deviceList -Force # force restarts every device in the array