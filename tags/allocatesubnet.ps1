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

# Get all app service plans which are already associated with this vnet
$apps = az appservice plan list --query "[?tags.vnet=='$vnetName']" | ConvertFrom-Json

# Is this a new app?
$app = $apps | Where-Object {$_.name -eq $aspName}

# If not new, does the app already have an assigned subnet?
if ($app -and $app.Tags.subnet)
{
  # If so, return that subnet and exit
  return $subnets | Where-Object {$_.name -eq $app.Tags.subnet}
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
  return $subnets[0]
}
# Or throw an error if there is nothing left
else 
{
  throw "All subnets for vnet $vnetName are currently in use."
}

# Finally, throw an error
throw "An unexpected error occured"