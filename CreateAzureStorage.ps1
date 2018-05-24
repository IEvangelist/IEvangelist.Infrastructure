## import / install azure modules
Import-Module -Name AzureRM
Install-Module AzureRmStorageTable

## Connect to azure
Connect-AzureRmAccount

## List storage account name
Get-AzureRMStorageAccount | Select StorageAccountName, Location


## Retrieve storage account name
$resourceGroup = "FunctionSandbox"
$storageAccountName = "functionstorage007"

$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageAccountName

## Retrieve the context. 
$ctx = $storageAccount.Context

## Create blob storage for images
$containerName = "imageblobs"
New-AzureStorageContainer -Name $containerName -Context $ctx -Permission blob

## Upload image
Set-AzureStorageBlobContent -File "C:\Hugo\Sites\davidpine.com\static\img\main\david.pine.jpg" `
  -Container $containerName `
  -Blob "me.jpg" `
  -Context $ctx

## List all blobs
Get-AzureStorageBlob -Container $ContainerName -Context $ctx | select Name

## Download image
Get-AzureStorageBlobContent -Blob "me.jpg" `
  -Container $containerName `
  -Destination "C:\Users\david.pine\Desktop\Download" `
  -Context $ctx 

## Create azure table
$tableName = "tablestorageisfun"
New-AzureStorageTable –Name $tableName –Context $ctx

## List all tables
Get-AzureStorageTable –Context $ctx | select Name

## Get reference to newly added table
$storageTable = Get-AzureStorageTable –Name $tableName –Context $ctx

## Add some data to these tables
$partitionKey1 = "partition1"
$partitionKey2 = "partition2"

# add four rows 
Add-StorageTableRow `
    -table $storageTable `
    -partitionKey $partitionKey1 `
    -rowKey ("CA") -property @{"username"="David";"userid"=1}

Add-StorageTableRow `
    -table $storageTable `
    -partitionKey $partitionKey2 `
    -rowKey ("NM") -property @{"username"="Patrick";"userid"=2}

Add-StorageTableRow `
    -table $storageTable `
    -partitionKey $partitionKey1 `
    -rowKey ("WA") -property @{"username"="Dan";"userid"=3}

Add-StorageTableRow `
    -table $storageTable `
    -partitionKey $partitionKey2 `
    -rowKey ("TX") -property @{"username"="Veera";"userid"=4}

## Query all
Get-AzureStorageTableRowAll -table $storageTable | ft

## Query by partion
Get-AzureStorageTableRowByPartitionKey -table $storageTable -partitionKey $partitionKey1 | ft

## Query the fearless leader
Get-AzureStorageTableRowByColumnName -table $storageTable `
    -columnName "username" `
    -value "Veera" `
    -operator Equal

## Query with custom filtering
Get-AzureStorageTableRowByCustomFilter `
    -table $storageTable `
    -customFilter "(userid eq 1)"
