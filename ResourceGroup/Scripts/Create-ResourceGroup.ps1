param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name,
    [Parameter(Mandatory = $true)]
    [string]
    $Location
)

$resourceGroup = $(az group list --query "[?name=='$Name']")

if ($resourceGroup -eq "[]") {
    az group create --name $Name --location $Location --output tsv
}
else {
    Write-Output "resource group $Name already exists"
}