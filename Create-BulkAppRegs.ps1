param (
    [Parameter(Mandatory = $true)]
    [string[]] $Owners,
    [Parameter(Mandatory = $true)]
    [String[]] $AppRegNames
)

foreach ($appReg in $AppRegNames) {
    [string] $appRegId = az ad app create --display-name $appReg --query "appId"
    az ad sp create-for-rbac --name $appReg --skip-assignment
    Write-Host "Created appreg: $appReg"

    foreach ($owner in $Owners) {
        [string] $ownerId = az ad user show --id $owner --query "objectId"
        az ad app owner add --id $appRegId --owner-object-id $ownerId
        Write-Host "$owner added as owner"
    }

    az ad app owner remove --id $appRegId --owner-object-id $(az ad signed-in-user show --query "objectId")
    Write-Host "Removed myself as owner"
}

# Example
# .\Create-BulkAppRegs.ps1 -Owners "john.doe@something.nl", "jane.doe@something.nl" -AppRegNames "AppRegNameA", "AppRegNameP"
