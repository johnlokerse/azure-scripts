param (
    [Parameter(Mandatory = $true)]
    [String]
    $Name,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("CanNotDelete", "ReadOnly")]
    [String]
    $Type,

    [bool]
    $Lock = $true
)

$resourceGroup = $(az group exists --resource-group $Name)

if ($resourceGroup) {
    $lockObject = Find-ResourceGroupLock -Name $Name
    if (!$lockObject.Locked) {
        az group lock create --Name [Guid]::NewGuid() --resource-group $Name --
    }
    else {
        # unlock
    }
}


function Find-ResourceGroupLock {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    $lock = $(az group lock list --resource-group $name --query [].name) | ConvertFrom-Json
    $lockObject = @{
        Locked   = ($null -ne $lock)
        LockName = $lock
    }

    return New-Object PSObject -Property $lockObject
}