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

    $MACPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # path to export MAC addresses to
    $allDevices = Get-CMDevice | Where-Object {$_.Name -match '^CM142-'} | Select-Object Name, MACAddress # gets all devices from SCCM that start with "CM142-"

    # Loop through each device and save MAC-to-Hostname mapping
    foreach ($device in $allDevices) {
        foreach ($MAC in $device.MACAddress) {
            $cleanMAC = $MAC -replace ":", "-" # replaces colons with dashes to comply with Windows file names
            $filePath = "$MACPath\$cleanMAC.txt" # full path
            $device.Name | Out-File -FilePath ('FileSystem::' + $filePath) -Encoding utf8 -Force # output hostname to mac.txt file
        }
    }
}