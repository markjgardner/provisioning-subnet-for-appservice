param(
  [Parameter(Mandatory=$true,
    HelpMessage="Name of the app you are creating")]
  [string]$aspName,
  [Parameter(Mandatory=$true,
    HelpMessage="Name of the integrated vnet")]
  [string]$vnetName,
  [Parameter(Mandatory=$true,
    HelpMessage="Name of the resource group containing the vnet")]
  [string]$vnetResourceGroup,
  [Parameter(Mandatory=$true,
    HelpMessage="Storage account containing the subnet assignment table")]
  [string]$storageAccount,
  [Parameter(Mandatory=$true,
    HelpMessage="Name of the subnet assignment table ")]
  [string]$tableName,
  [Parameter(HelpMessage="Size of the subnet to allocate (default is 27)")]
  [ValidateRange(1,32)]
  [int]$subnetSize=27
)

# Get all subnets (and their assigned ASPs) for the given vnet
$subnets = az storage entity query --table-name $tableName --account-name $storageAccount --filter "PartitionKey eq '$vnetName' and size eq $subnetSize" | ConvertFrom-Json

# Check if the app already has a subnet assigned
$subnet = $subnets.items | Where-Object {$_.aspName -eq $aspName}
if ($subnet)
{
  # If so, return that subnet and exit
  return $subnet
}

# Otherwise, grab an available subnet
$subnet = $subnets.items | Where-Object {$_.aspName -eq $null}
if ($subnet)
{
  # If so, mark the subnet as in use and return it
  $update = @{
    PartitionKey = $subnet.PartitionKey
    RowKey = $subnet.RowKey
    size = $subnet.Size
    aspName = $aspName
    etag = $subnet.etag
  }
  az storage entity replace --table-name $tableName --account-name $storageAccount --entity $update
  return $subnet
}
# Or throw an error if there are none left
else 
{
  throw "All subnets for vnet $vnetName are currently in use."
}

# Finally, throw an error
throw "An unexpected error occured"