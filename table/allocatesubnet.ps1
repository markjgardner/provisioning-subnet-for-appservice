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
    HelpMessage="Name of the resource group containing the storage account")]
  [string]$storageResourceGroup,
  [Parameter(Mandatory=$true,
    HelpMessage="Name of the subnet assignment table ")]
  [string]$tableName,
  [Parameter(HelpMessage="Size of the subnet to allocate (default is 27)")]
  [ValidateRange(1,32)]
  [int]$subnetSize=27
)
Install-Module AzTable -Force -AllowClobber

# Setup
$storage = Get-AzStorageAccount -ResourceGroupName $storageResourceGroup -Name $storageAccount
$table = (Get-AzStorageTable –Context $storage.Context -Name $tableName).CloudTable

# Get all subnets available for the given vnet
$subnets = Get-AzTableRow -table $table -customFilter "(PartitionKey eq '$vnetName' and size eq $subnetSize)"
Write-Information "Found $($subnets.Count) subnets in $vnetName"

# Check if the app already has a subnet assigned
$subnet = $subnets | Where-Object {$_.aspName -eq $aspName}
if ($subnet)
{
  # If so, return that subnet and exit
  Write-Information "ASP $aspName is already integrated with subnet $($subnet.RowKey)"
  write-host "##vso[task.setvariable variable=subnetName]$($subnet.RowKey)"
  return $subnet
}

# Otherwise, grab an available subnet
$subnet = $subnets | Where-Object {$_.aspName -eq $null} | Select-Object -First 1
if ($subnet)
{
  # If one is available, mark the subnet as in use and return it
  $subnet | Add-Member -NotePropertyName aspName -NotePropertyValue $aspName 
  $update = $subnet | Update-AzTableRow -table $table
  write-host "##vso[task.setvariable variable=subnetName]$($subnet.RowKey)"
  return $subnet
}
# Or throw an error if there are none left
else 
{
  throw "All subnets for vnet $vnetName are currently in use."
}

# Finally, throw an error
throw "An unexpected error occured"
