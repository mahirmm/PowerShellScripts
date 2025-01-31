# Define SCCM Site Code and Provider Machine
$SiteCode = "380"  # SCCM Site Code
$ProviderMachineName = "odin.project.co3808.com"  # SCCM Provider Machine

# Import SCCM PowerShell Module if not already loaded
if (-not (Get-Module ConfigurationManager)) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction Stop
}

# Ensure SCCM drive exists, then switch to it
if (-not (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName -ErrorAction Stop
}

# Change location to SCCM site
Set-Location "$($SiteCode):" -ErrorAction Stop

# Define collection name
$collectionName = "Disk Space Below 40G"

# Get the list of device names in the collection
$devices = Get-CMDeviceCollectionDirectMembershipRule -CollectionName $collectionName

# If devices exist, remove them
if ($devices) {
    foreach ($device in $devices) {
        Remove-CMDeviceCollectionDirectMembershipRule -CollectionName $collectionName -ResourceID $device.ResourceID -Force
        Write-Output "Removed $($device.Name) from collection $collectionName"
    }
} else {
    Write-Output "No devices found in collection: $collectionName"
}
