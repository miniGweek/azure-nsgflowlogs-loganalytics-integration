# Usage as follows:
# .\Get-NsgFlowLogs.ps1 -SubscriptionName "Visual Studio Enterprise Subscription – MPN" -StorageAccountName stsxiqdevnsgflowlogs -StartTime "10/27/2021 03:30" -EndTime  "10/27/2021 04:30"
param(
    [string] [Parameter(Mandatory = $true)]$SubscriptionName,
    [string] $NSGName,
    [string] [Parameter(Mandatory = $true)]$StorageAccountName,    
    [string]$MacAddress,
    [datetime][Parameter(Mandatory = $true)]$StartTime,
    [datetime]$EndTime = "01/01/1970"
)
function Get-NSGFlowLogCloudBlockBlob {
    [CmdletBinding()]
    param (
        [string] [Parameter(Mandatory = $true)] $subscriptionId,    
        [string] [Parameter(Mandatory = $true)] $NSGName,
        [string] [Parameter(Mandatory = $true)] $NSGResourceGroupName,
        [string] [Parameter(Mandatory = $true)] $storageAccountName, 
        [string][Parameter(Mandatory = $true)]  $StorageAccountKey, 
        [Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext][Parameter(Mandatory = $true)] $Ctx, 
        [string] $macAddress,
        [datetime] [Parameter(Mandatory = $true)] $logTime
    )

    process {
        # Retrieve the primary storage account key to access the NSG logs
        # Container name used by NSG flow logs
        $ContainerName = "insights-logs-networksecuritygroupflowevent"

        # Name of the blob that contains the NSG flow log
        $subscriptionId = $subscriptionId.ToUpper();
        # $NSGResourceGroup = Get-AzNetworkSecurityGroup | Where-Object { $_.Name -eq $NSGName }
        $NSGResourceGroupName = $NSGResourceGroupName.ToUpper();
        $NSGName = $NSGName.ToUpper();
        
        $CloudBlockBlobs = @();
        if ($MacAddress.Length -gt 0) {
            $BlobName = "resourceId=/SUBSCRIPTIONS/${subscriptionId}/RESOURCEGROUPS/${NSGResourceGroupName}/PROVIDERS/MICROSOFT.NETWORK/NETWORKSECURITYGROUPS/${NSGName}/y=$($logTime.Year)/m=$(($logTime).ToString("MM"))/d=$(($logTime).ToString("dd"))/h=$(($logTime).ToString("HH"))/m=00/macAddress=$($macAddress)/PT1H.json"
            $Blob = Get-AzStorageBlob -Context $Ctx -Container $ContainerName -Blob $BlobName

            # Gets the block blog of type 'Microsoft.Azure.Storage.Blob.CloudBlob' from the storage blob
            $CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob
            $CloudBlockBlobs += $CloudBlockBlob
        }
        else {
            $BlobName = "resourceId=/SUBSCRIPTIONS/${subscriptionId}/RESOURCEGROUPS/${NSGResourceGroupName}/PROVIDERS/MICROSOFT.NETWORK/NETWORKSECURITYGROUPS/${NSGName}/y=$($logTime.Year)/m=$(($logTime).ToString("MM"))/d=$(($logTime).ToString("dd"))/h=$(($logTime).ToString("HH"))/m=00/"
            $Blobs = Get-AzStorageBlob -Context $Ctx -Container $ContainerName -Prefix $BlobName
           
            foreach ($Blob in $Blobs) {
                # Gets the block blog of type 'Microsoft.Azure.Storage.Blob.CloudBlob' from the storage blob
                $CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob
                $CloudBlockBlobs += $CloudBlockBlob
            }
        }
        #Return the Cloud Block Blob
        $CloudBlockBlobs
    }
}

function Get-NSGFlowLogBlockList {
    [CmdletBinding()]
    param (
        [Microsoft.Azure.Storage.Blob.CloudBlockBlob] [Parameter(Mandatory = $true)] $CloudBlockBlob
    )
    process {
        # Stores the block list in a variable from the block blob.
        $blockList = $CloudBlockBlob.DownloadBlockList()

        # Return the Block List
        $blockList
    }
}

function Get-NSGFlowLogReadBlock {
    [CmdletBinding()]
    param (
        [System.Array] [Parameter(Mandatory = $true)] $blockList,
        [Microsoft.Azure.Storage.Blob.CloudBlockBlob] [Parameter(Mandatory = $true)] $CloudBlockBlob

    )
    # Set the size of the byte array to the largest block
    $maxvalue = ($blocklist | Measure-Object Length -Maximum).Maximum

    # Create an array to store values in
    $valuearray = @()

    # Define the starting index to track the current block being read
    $index = 0

    # Loop through each block in the block list
    for ($i = 0; $i -lt $blocklist.count; $i++) {
        # Create a byte array object to story the bytes from the block
        $downloadArray = New-Object -TypeName byte[] -ArgumentList $maxvalue

        # Download the data into the ByteArray, starting with the current index, for the number of bytes in the current block. Index is increased by 3 when reading to remove preceding comma.
        $CloudBlockBlob.DownloadRangeToByteArray($downloadArray, 0, $index, $($blockList[$i].Length)) | Out-Null

        # Increment the index by adding the current block length to the previous index
        $index = $index + $blockList[$i].Length

        # Retrieve the string from the byte array

        $value = [System.Text.Encoding]::ASCII.GetString($downloadArray)

        # Add the log entry to the value array
        $valuearray += $value
    }
    #Return the Array
    $valuearray
}


$SubscriptionContext = Set-AzContext -SubscriptionName $SubscriptionName
$SubscriptionId = $(Get-AzSubscription -SubscriptionName $SubscriptionName).SubscriptionId 
$StorageAccount = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $StorageAccountName }
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.ResourceGroupName -Name $StorageAccountName).Value[0]
# Setup a new storage context to be used to query the logs
$Ctx = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $StorageAccountKey

$CloudBlockBlobs = @();

$StartTime = $StartTime.AddMinutes(-$StartTime.Minute)   # Discarding minutes part and only using hours
$EndTime = $EndTime.AddMinutes(-$EndTime.Minute) # Discarding minutes part and only using hours
$TotalHours = 0
if ($EndTime -gt $StartTime) {
    $TimeSpan = New-TimeSpan -Start $StartTime -End $EndTime
    $TotalHours = $TimeSpan.Days * 24 + $TimeSpan.Hours
}

for ($Index = 0; $Index -le $TotalHours; $Index++ ) {
  
   
    if ($NSGName.Length -gt 0) {
        $NSG = Get-AzNetworkSecurityGroup | Where-Object { $_.Name -eq $NSGName }
        
        $CloudBlockBlob = Get-NSGFlowLogCloudBlockBlob -subscriptionId $SubscriptionId `
            -storageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey  -Ctx $Ctx `
            -NSGName $NSGName  -NSGResourceGroupName $NSG.ResourceGroupName `
            -macAddress $MacAddress -logTime $StartTime
    
        $CloudBlockBlobs += $CloudBlockBlob
    }
    else {
        $NSGs = Get-AzNetworkSecurityGroup
        foreach ($NSG in $NSGs) {
            $CloudBlockBlob = Get-NSGFlowLogCloudBlockBlob -subscriptionId $SubscriptionId `
                -storageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey  -Ctx $Ctx `
                -NSGName $NSG.Name  -NSGResourceGroupName $NSG.ResourceGroupName `
                -logTime $StartTime
    
            $CloudBlockBlobs += $CloudBlockBlob
        }
    }

    $StartTime = $StartTime.AddHours(1)    
}


$Records = New-Object Collections.Generic.List[PSCustomObject]
Write-Host "Total CloudBlockBlobs to iterate :$($CloudBlockBlobs.Length)"
$CloudBlockBlobIndex = 0;
foreach ($CloudBlockBlob in $CloudBlockBlobs) {
    $CloudBlockBlobIndex++;
    $blockList = Get-NSGFlowLogBlockList -CloudBlockBlob $CloudBlockBlob
    $valuearray = Get-NSGFlowLogReadBlock -blockList $blockList -CloudBlockBlob $CloudBlockBlob
    $valuearrayjsonstring = $valuearray -join ""
    $valuerraylistobject = ConvertFrom-Json $valuearrayjsonstring
    foreach ($value in $valuerraylistobject.records) {    
        foreach ($NSGFlowRecord in $value.properties.flows) {
            foreach ($flow in $NSGFlowRecord.flows) {
                foreach ($flowtuple in $flow.flowTuples) {
                    $FlowTupleMembers = $flowtuple -Split ","
                    $TimeRecord = [PSCustomObject]@{
                        TimeGenerated                = $value.time
                        MacAddress                   = $value.macAddress
                        ResourceId                   = $value.resourceId
                        Rule                         = $NSGFlowRecord.rule
                        TimeWhenOcurred              = (Get-Date 01.01.1970) + ([System.TimeSpan]::FromSeconds($FlowTupleMembers[0]))
                        SourceIP                     = $FlowTupleMembers[1]
                        DestinationIp                = $FlowTupleMembers[2]
                        SourcePort                   = $FlowTupleMembers[3]
                        DestinationPort              = $FlowTupleMembers[4]
                        Protocol                     = $FlowTupleMembers[5]
                        TrafficFlow                  = $FlowTupleMembers[6]
                        TrafficDecision              = $FlowTupleMembers[7]
                        FlowState                    = $FlowTupleMembers[8]
                        PacketsSourceToDestination   = $FlowTupleMembers[9]
                        BytessentSourceToDestination = $FlowTupleMembers[10]
                        PacketsDestinationToSource   = $FlowTupleMembers[11]
                        BytessentDestinationToSource = $FlowTupleMembers[12]
                    }
                    $Records.Add($TimeRecord)
                }
            }
     
        }
    }
    Write-Host "Processed CloudBlockBlob index:$CloudBlockBlobIndex"

    $FileLogTimeIdentifier = $StartTime.ToString("ddMMyyyyhhmmss")
    $CsvFileName = "Nsgflowlogs_$($NSGName)_$($MacAddress)_$FileLogTimeIdentifier.csv" 
    $Records | Export-Csv -Path $CsvFileName -Append
    Write-Host "Appended CloudBlockBlob data at index:$CloudBlockBlobIndex to csv"
    $Records    
}


