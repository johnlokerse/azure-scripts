param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name,

    [Parameter(Mandatory = $true)]
    [string]
    $Location
)

$resourceGroup = $(az group exists --resource-group $Name)

if (!$resourceGroup) {
    az group create --name $Name --location $Location --output tsv
}
else {
    Write-Output "resource group $Name already exists"
}