param (
    [Parameter(Mandatory = $true)]
    [string] $ClientId,
    [Parameter(Mandatory = $true)]
    [string] $ClientSecret,
    [Parameter(Mandatory = $true)]
    [string] $TenantId,
    [Parameter(Mandatory = $true)]
    [string] $LogFileLocation
)


# Set flag to install extensions without prompt
az config set extension.use_dynamic_install=yes_without_prompt

# Login with the Service Principal credentials
az login --service-principal --username $ClientId --password $ClientSecret --tenant $TenantId --only-show-errors

# Set explicit path
[string] $logFile = "$LogFileLocation/UntaggedResources.json"

# Set tag key
[string] $tagKey = "<set_tag_key>"

# Classes
class ResourceGroup {
    ResourceGroup([string] $SubscriptionName, [string] $DisplayName, [string[]] $UntaggedResource) {
        $this.SubscriptionName = $SubscriptionName
        $this.DisplayName = $DisplayName
        $this.UntaggedResource = $UntaggedResource
    }
    [string] $SubscriptionName
    [string] $DisplayName
    [string[]] $UntaggedResource
}

class Azure {
    [string] $Subscription
    [ResourceGroup[]] $ResourceGroup
}

# Functions
function Get-SubscriptionList {
    param (
        [string] $Query
    )
    
    if (-not $Query) {
        return az account subscription list --only-show-errors
    }

    return az account subscription list --only-show-errors --query $Query
}

function Get-ResourceGroupList {
    param (
        [Parameter(Mandatory = $true)]
        [string] $SubscriptionName,
        [string] $Query
    )

    if (-not $Query) {
        return az group list --subscription $SubscriptionName
    }

    return az group list --subscription $SubscriptionName --query $Query
}

function Get-ExclusionString {
    param (
        [Parameter(Mandatory = $true)]
        [string[]] $ExclusionList,
        [Parameter(Mandatory = $false)]
        [bool] $ForResourceGroup
    )

    if (-not $ExclusionList -Or $ExclusionList.Length -le 0) {
        return [string]::Empty
    }

    [string] $containsKey = "displayName"
    if ($ForResourceGroup) {
        $containsKey = "name"
    }

    [string] $exclusionString = [string]::Empty
    foreach ($item in $ExclusionList) {
        if ($item -ne $ExclusionList[-1]) {
            $exclusionString += "!contains($containsKey, '$item') && "
        }
        else {
            $exclusionString += "!contains($containsKey, '$item')"
        }
    }

    return $exclusionString    
}

Write-Host "---- Looking through subscriptions and *BASE* resource groups ----"

[string[]] $subscriptionExclusionList = @()
[string[]] $resourceGroupExclusionList = @()
[string[]] $subscriptions = (Get-SubscriptionList -Query "[?$(Get-ExclusionString -ExclusionList $subscriptionExclusionList -ForResourceGroup $false)]" | ConvertFrom-Json).displayName
[ResourceGroup[]] $resourceGroupObjects = @()

foreach ($subscription in $subscriptions) {
    $listedResourceGroups = (Get-ResourceGroupList -SubscriptionName $subscription -Query "[?contains(name, 'BASE') && $(Get-ExclusionString -ExclusionList $resourceGroupExclusionList -ForResourceGroup $true)]" | ConvertFrom-Json)
    foreach ($rg in $listedResourceGroups) {
        [ResourceGroup] $taggedResourceGroup = [ResourceGroup]::new($subscription, $rg.Name, $null)
        $resourceGroupObjects += $taggedResourceGroup
    }
}

Write-Host "---- Looking for untagged InSpark managed resources ----"

# Add resourceTypes to the list
[string] $resourceTypes = @"
'Microsoft.Compute/virtualMachines',
'Microsoft.Compute/availabilitySets',
'Microsoft.Network/virtualNetworks',
'Microsoft.Network/networkSecurityGroups',
'Microsoft.Network/applicationSecurityGroups',
'Microsoft.Network/bastionHosts',
'Microsoft.Storage/storageAccounts',
'Microsoft.Network/loadBalancers',
'Microsoft.Network/publicIPAddresses',
'Microsoft.Network/virtualNetworkGateways',
'Microsoft.Network/localNetworkGateways',
'Microsoft.Network/connections',
'Microsoft.Network/routeTables',
'Microsoft.Network/expressRouteCircuits',
'Microsoft.StorageSync/storageSyncServices',
'Microsoft.RecoveryServices/vaults',
'Microsoft.Network/networkWatchers',
'Microsoft.Web/sites',
'Microsoft.Web/sites/slots',
'Microsoft.Web/serverfarms',
'Microsoft.Web/hostingEnvironments',
'Microsoft.ApiManagement/service',
'Microsoft.Sql/managedInstances',
'Microsoft.Sql/servers',
'Microsoft.Sql/servers/elasticPools',
'Microsoft.Sql/servers/databases',
'Microsoft.Automation/automationAccounts',
'Microsoft.AAD/domainServices',
'Microsoft.KeyVault/vaults',
'Microsoft.Network/azureFirewalls',
'Microsoft.Network/applicationGateways',
'Microsoft.Network/frontDoors',
'Microsoft.ContainerService/managedClusters',
'Microsoft.ContainerInstance/containerGroups',
'Microsoft.ContainerRegistry/registries'
"@.Replace("`n", "")

foreach ($item in $resourceGroupObjects) {
    if ($null -ne $item.DisplayName) {
        $untaggedResources = (az resource list --resource-group $item.DisplayName --subscription $item.SubscriptionName --query "[?contains([$resourceTypes], type)]" | ConvertFrom-Json).name
        if ($null -ne $untaggedResources) {
            $selectRG = ($resourceGroupObjects | Where-Object { $_.DisplayName -eq $item.DisplayName -And $_.SubscriptionName -eq $item.SubscriptionName })
            $selectRG.UntaggedResource = $untaggedResources
        }
    }
}


$untaggedResourceGroupObjects = $resourceGroupObjects | Where-Object { $null -ne $_.UntaggedResource }
$untaggedResourceGroupObjects | ConvertTo-Json -Depth 10 | Out-File $logFile

if ($untaggedResourceGroupObjects.Length -ne 0) {
    Write-Host "##vso[task.logissue type=error]Er zijn resources gevonden die niet getagd zijn."
    if (Test-Path $logFile) {
        Get-Content $logFile
    } else {
        Write-Host "##vso[task.logissue type=error]$logFile is niet gevonden."
        exit 2
    }
    exit 1
}

Write-Host "##vso[task.complete result=Succeeded;]Alle resources zijn getagd."
