<#
.SYNOPSIS
    Performs actions to create Azure AD Application Registrations with Service Principals
.EXAMPLE
    PS> .\Create-BulkAppRegs.ps1 -Owners "john.doe@something.nl", "jane.doe@something.nl" -AppRegNames "AppRegNameA", "AppRegNameP"

    Creates application registrations AppRegNameA and AppRegNameP. After creating these the owners john.doe and jane.doe are added to these application registrations.
.PARAMETER Owners
    This describes the owners that need to be added to the application registrations. [array]
.PARAMETER AppRegNames
    This describes the application registrations that need to be created. [array]
#>
param (
    [Parameter(Mandatory = $true)]
    [string[]] $Owners,
    [Parameter(Mandatory = $true)]
    [String[]] $AppRegNames
)

function Remove-GeneratedSecret {
    param (
        [string]
        [ValidateNotNullOrEmpty()]
        $Id
    )

    $rbacObject = (az ad sp credential list --id $id --query "[?customKeyIdentifier == 'rbac']" | ConvertFrom-Json)
    if (! [String]::IsNullOrEmpty($rbacObject.customKeyIdentifier)) {
        Write-Host "Removing default secret"
        az ad sp credential delete --id $id --key-id $rbacObject.keyId
    }
}

function Set-AnnounceMessage {
    param (
        [string]
        [ValidateNotNullOrEmpty()]
        $Msg
    )

    Write-Host -ForegroundColor Yellow -Message $Msg
}

foreach ($appReg in $AppRegNames) {
    Set-AnnounceMessage -Msg "----------- Start $appReg -----------"

    [string] $appRegId = (az ad app create --display-name $appReg --only-show-errors --query "appId" ).Trim('"')
    az ad sp create-for-rbac --name $appReg --skip-assignment --only-show-errors --output none
    Write-Host "Created app registration: $appReg with ID $appRegId"

    foreach ($owner in $Owners) {
        [string] $ownerId = az ad user show --id $owner --query "objectId"
        az ad app owner add --id $appRegId --owner-object-id $ownerId
        Write-Host "$owner added as owner"
    }

    Remove-GeneratedSecret -Id $appRegId

    Set-AnnounceMessage -Msg "----------- End $appReg -----------"
}
