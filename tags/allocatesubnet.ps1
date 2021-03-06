param(
  [Parameter(Mandatory=$true,
    HelpMessage="The name of the app you are creating")]
  [string]$aspName,
  [Parameter(Mandatory=$true,
    HelpMessage="The name of the integrated vnet")]
  [string]$vnetName,
  [Parameter(Mandatory=$true,
    HelpMessage="The name of the resource group containing the vnet")]
  [string]$vnetResourceGroup,
  [Parameter(HelpMessage="The size of the subnet to allocate (default is 27)")]
  [ValidateRange(1,32)]
  [int]$subnetSize=27
)
# Get all subnets available in the vnet
[System.Collections.ArrayList]$subnets = az network vnet subnet list -g $vnetResourceGroup --vnet-name $vnetName --query "[?addressPrefix | ends_with(@,'$subnetSize')]" | ConvertFrom-Json
Write-Information "Found $($subnets.Count) subnets in $vnetName"

# Get all app service plans which are already associated with this vnet
$apps = az appservice plan list --query "[?tags.vnet=='$vnetName']" | ConvertFrom-Json
Write-Information "Found $($apps.Count) app service plans integrated with $vnetName"

# Is this a new app?
$app = $apps | Where-Object {$_.name -eq $aspName}

# If not new, does the app already have an assigned subnet?
if ($app -and $app.Tags.subnet)
{
  # If so, return that subnet and exitx
  $result = $subnets | Where-Object {$_.name -eq $app.Tags.subnet}
  Write-Information "ASP $aspName is already integrated with subnet $($result.name)"
  Write-Host "##vso[task.setvariable variable=subnetName]$($result.name)"
  Write-Information $result
  exit 0
}

# Find an available subnet by eliminating all allocated subnets
foreach ($app in $apps)
{
  if ($app.Tags.subnet)
  {
    $sn = $subnets | Where-Object {$_.name -eq $app.Tags.subnet}
    $subnets.Remove($sn)
  }
}

# Allocate a subnet from whatever is left
if ($subnets.Count -gt 0)
{
  $result = $subnets[0]
  write-host "##vso[task.setvariable variable=subnetName]$($result.name)"
  Write-Information $result
  exit 0
}
# Or throw an error if there is nothing left
else 
{
  throw "All subnets for vnet $vnetName are currently in use."
}

# Finally, throw an error
throw "An unexpected error occured"