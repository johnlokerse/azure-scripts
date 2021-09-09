<#
.SYNOPSIS
    Performs actions to create Azure AD Application Registrations with Service Principals
.EXAMPLE
    PS> .\Create-BulkAppRegs.ps1 -Owners "john.doe@something.nl", "jane.doe@something.nl" -AppRegNames "AppRegNameA", "AppRegNameP"

    Creates application registrations AppRegNameA and AppRegNameP. After creating these the owners john.doe and jane.doe are added to these application registrations.
.PARAMETER Owners
    This describes the owners that need to be added to the appregistration. [array]
.PARAMETER AppRegNames
    This describes the appregistrations that need to be created. [array]
#>
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
