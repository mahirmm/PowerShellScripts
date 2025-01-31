Write-Host "Blocking PXE boot - Less than 30 mins left in break."

# Disable PXE deployment for collection
Invoke-Command -ScriptBlock {
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
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

    #Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
    #cd "SCCM:"
    Get-CMDeviceCollection -Name "Win 10 Deployment" #"Disk Space Below 40G" #| Clear-CMPxeDeployment
}
