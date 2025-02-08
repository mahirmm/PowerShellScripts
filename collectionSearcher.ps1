$SiteCode = "380"
$ProviderMachineName = "odin.project.co3808.com"
$computerName = "CM142-001" # computer name to search

# REF
## https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
$collectionSearcher = Get-WmiObject -ComputerName $ProviderMachineName -Namespace root/SMS/site_$SiteCode -Query "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection where name = '$ComputerName' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID and CollectionID NOT LIKE 'SMS%'"
$collectionSearcher | Select-Object -Property Name,CollectionID