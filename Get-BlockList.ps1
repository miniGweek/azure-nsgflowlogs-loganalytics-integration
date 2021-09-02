function Get-NSGFlowLogCloudBlockBlob {
    [CmdletBinding()]
    param (
        [string] [Parameter(Mandatory = $true)] $subscriptionId,
        [string] [Parameter(Mandatory = $true)] $NSGResourceGroupName,
        [string] [Parameter(Mandatory = $true)] $NSGName,
        [string] [Parameter(Mandatory = $true)] $storageAccountName,
        [string] [Parameter(Mandatory = $true)] $storageAccountResourceGroup,
        [string] [Parameter(Mandatory = $true)] $macAddress,
        [datetime] [Parameter(Mandatory = $true)] $logTime
    )

    process {
        # Retrieve the primary storage account key to access the NSG logs
        $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccountResourceGroup -Name $storageAccountName).Value[0]

        # Setup a new storage context to be used to query the logs
        $ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

        # Container name used by NSG flow logs
        $ContainerName = "insights-logs-networksecuritygroupflowevent"

        # Name of the blob that contains the NSG flow log
        $subscriptionId = $subscriptionId.ToUpper();
        $NSGResourceGroupName = $NSGResourceGroupName.ToUpper();
        $NSGName = $NSGName.ToUpper();

        $BlobName = "resourceId=/SUBSCRIPTIONS/${subscriptionId}/RESOURCEGROUPS/${NSGResourceGroupName}/PROVIDERS/MICROSOFT.NETWORK/NETWORKSECURITYGROUPS/${NSGName}/y=$($logTime.Year)/m=$(($logTime).ToString("MM"))/d=$(($logTime).ToString("dd"))/h=$(($logTime).ToString("HH"))/m=00/macAddress=$($macAddress)/PT1H.json"

        # Write-Host  $BlobName
        # Gets the storage blog
        $Blob = Get-AzStorageBlob -Context $ctx -Container $ContainerName -Blob $BlobName

        # Gets the block blog of type 'Microsoft.Azure.Storage.Blob.CloudBlob' from the storage blob
        $CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob

        #Return the Cloud Block Blob
        $CloudBlockBlob
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


$CloudBlockBlob = Get-NSGFlowLogCloudBlockBlob -subscriptionId "c72448e0-7dcd-4bf4-adfc-ec46f8810bc4" -NSGResourceGroupName "rg-prd-occub-services-001" `
    -NSGName "nsg-prd-occub-app-001" -storageAccountName "stasahigoccubprd" -storageAccountResourceGroup "rg-prd-occub-services-001" `
    -macAddress "0022480FD8FF" -logTime "09/01/2021 07:00" 

# $CloudBlockBlob
    
$blockList = Get-NSGFlowLogBlockList -CloudBlockBlob $CloudBlockBlob
# $blockList

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
$valuearray = Get-NSGFlowLogReadBlock -blockList $blockList -CloudBlockBlob $CloudBlockBlob

$valuearrayjsonstring = $valuearray -join ""

$valuerraylistobject = ConvertFrom-Json $valuearrayjsonstring
$valuerraylistobject
# for ($i = 1; $i -lt $valuearray.Length - 1; $i++) {
#     Write-Host $valuearray[$i];
#     if ($i -eq 5) {
#         break;
#     }
# }