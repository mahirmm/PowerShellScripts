$SCCMServer = "odin.project.co3808.com"
$SiteCode = "380"
$Username = "PROJECT\administrator"
$Password = ConvertTo-SecureString "Shaolin124?@#" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
$computerName = $env:COMPUTERNAME

$Session = New-PSSession -ComputerName $SCCMServer -Credential $Credential

Invoke-Command -Session $Session -ScriptBlock {
    param ($SiteCode, $SCCMServer, $computerName)

    Import-Module ($ENV:SMS_ADMIN_UI_PATH + "\..\ConfigurationManager.psd1") -ErrorAction Stop
    Set-Location "$SiteCode`:"
    
    $collectionSearcher = Get-WmiObject -ComputerName $SCCMServer -Namespace "root/SMS/site_$SiteCode" `
        -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$computerName' AND SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID AND CollectionID NOT LIKE 'SMS%'"

    if ($computerName -eq "Unknown-PC"){
            break
    } else {
        # REF
        ## https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
        $collectionSearcher = Get-WmiObject -ComputerName $SCCMServer -Namespace root/SMS/site_$SiteCode -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$computerName' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID and CollectionID NOT LIKE 'SMS%'"
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

    $logPath = "\\ODIN\Users\Administrator\Desktop\SCCM\SCCM Boot Images\Logs" # UNC path to log folder
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss" # current date/time
    $logFile = "$logPath\$computerName-Imaging.log" # file name to create/append

    "Included Collections: $collectionList" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "Imaging End: $timestamp" | Out-File -FilePath ('FileSystem::' + $logFile) -Append
    "--------------------------------------------------" | Out-File -FilePath ('FileSystem::' + $logFile) -Append

} -ArgumentList $SiteCode, $SCCMServer, $computerName

Remove-PSSession $Session
