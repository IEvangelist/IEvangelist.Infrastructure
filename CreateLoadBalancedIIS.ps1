## Create a resource group
New-AzureRmResourceGroup `
  -ResourceGroupName "DpLoadBalancer" `
  -Location "EastUS"

## Public IP
$publicIP = New-AzureRmPublicIpAddress `
  -ResourceGroupName "DpLoadBalancer" `
  -Location "EastUS" `
  -AllocationMethod "Static" `
  -Name "DpPublicIP"

## Creates a front-end IP
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig `
  -Name "FrontEndPool" `
  -PublicIpAddress $publicIP

## Creates a backend address pool
$backendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "BackEndPool"


$lb = New-AzureRmLoadBalancer `
  -ResourceGroupName "DpLoadBalancer" `
  -Name "DpLoadBalancer" `
  -Location "EastUS" `
  -FrontendIpConfiguration $frontendIP `
  -BackendAddressPool $backendPool

## Create health probe
Add-AzureRmLoadBalancerProbeConfig `
  -Name "DpHealthProbe" `
  -LoadBalancer $lb `
  -Protocol tcp `
  -Port 80 `
  -IntervalInSeconds 15 `
  -ProbeCount 2

## Load the load balancer
Set-AzureRmLoadBalancer -LoadBalancer $lb

## Get health probe instance
$probe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "DpHealthProbe"

## Create LB rule config
Add-AzureRmLoadBalancerRuleConfig `
  -Name "DpLoadBalancerRule" `
  -LoadBalancer $lb `
  -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] `
  -BackendAddressPool $lb.BackendAddressPools[0] `
  -Protocol Tcp `
  -FrontendPort 80 `
  -BackendPort 80 `
  -Probe $probe

## Update
Set-AzureRmLoadBalancer -LoadBalancer $lb


## Create subnet config
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
  -Name "DpSubnet" `
  -AddressPrefix 192.168.1.0/24

## Create the virtual network
$vnet = New-AzureRmVirtualNetwork `
  -ResourceGroupName "DpLoadBalancer" `
  -Location "EastUS" `
  -Name "DpVnet" `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig

for ($i=1; $i -le 3; ++ $i) {
   New-AzureRmNetworkInterface `
     -ResourceGroupName "DpLoadBalancer" `
     -Name "Dp$iNic" `
     -Location "EastUS" `
     -Subnet $vnet.Subnets[0] `
     -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0]
}


## Create VMs
$availabilitySet = New-AzureRmAvailabilitySet `
  -ResourceGroupName "DpLoadBalancer" `
  -Name "DpAvailabilitySet" `
  -Location "EastUS" `
  -Sku aligned `
  -PlatformFaultDomainCount 2 `
  -PlatformUpdateDomainCount 2

$cred = Get-Credential

for ($i=1; $i -le 3; ++ $i) {
    New-AzureRmVm `
        -ResourceGroupName "DpLoadBalancer" `
        -Name "Dp$i" `
        -Location "East US" `
        -VirtualNetworkName "DpVnet" `
        -SubnetName "mySubnet" `
        -SecurityGroupName "DpNetworkSecurityGroup" `
        -OpenPorts 80 `
        -AvailabilitySetName "DpAvailabilitySet" `
        -Credential $cred `
        -AsJob
}

## IIS Bits...
for ($i=1; $i -le 3; ++ $i) {
   Set-AzureRmVMExtension `
     -ResourceGroupName "DpLoadBalancer" `
     -ExtensionName "IIS" `
     -VMName "Dp$i" `
     -Publisher Microsoft.Compute `
     -ExtensionType CustomScriptExtension `
     -TypeHandlerVersion 1.8 `
     -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
     -Location EastUS
}
