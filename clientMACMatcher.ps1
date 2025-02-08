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

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    $logFile = "$logPath\$computerName-Imaging.log" # file name to create/append
    #$logFile = "$logPath\TS-Imaging.log" # file name to create/append

    # append data to log file
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append # append data to file / create file if not exist
    "Imaging Start: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    #"Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Computer Name: $computerName" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    #"MACreal: $MACreal" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    #"--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
}