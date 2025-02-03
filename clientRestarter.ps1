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
#$collectionName = "CM142 Lab" # collection to run command against
$collectionDevices = Get-CMDevice -CollectionName $collectionName # obtains device info on all devices in the colelction
$deviceList = @() # creates empty array
foreach ($device in $collectionDevices) { # for every device in the collection
    $deviceList += $device.Name # append device name to array 'name1, name2, name3'
}

# searches for all devices in array that does NOT have a logged in user and stores results in variable
$noLoggedinUsers = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $deviceList |
    Where-Object {-Not $_.Username} |
    Select-Object -ExpandProperty Name

Write-Host $noLoggedinUsers
#Restart-Computer -ComputerName $deviceList -Force # force restarts every device in the array that does not have an active user