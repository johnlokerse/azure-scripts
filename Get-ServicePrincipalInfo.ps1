param (
    [Parameter(Mandatory = $true)]
    [string]
    $DisplayName
)

az ad sp list --display-name $DisplayName --query "[].{Name: displayName, ApplicationID: appId, ObjectID: objectId}"