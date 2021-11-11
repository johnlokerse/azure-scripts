param (
    [Parameter(Mandatory = $true)]
    [string]
    $GroupName
)

az ad group show -g $GroupName --query "[].{Name: displayName, ObjectID: objectId, LastSync: lastDirSyncTime}"
