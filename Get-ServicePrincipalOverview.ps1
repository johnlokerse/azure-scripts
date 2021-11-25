param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DisplayName
)

class ServicePrincipal {
    [string] $displayName
    [string] $appId
    [string] $objectId
    [bool] $accountEnabled
}

class ServicePrincipalOwner {
    [string] $displayName
    [string] $mail
}

class ServicePrincipalSecrets {
    [string] $keyId
    [string] $startDate
    [string] $endDate
}

[ServicePrincipal] $sp = az ad sp list --display-name $DisplayName | ConvertFrom-Json | Select-Object -Property displayName, appId, objectId, accountEnabled
if ($null -eq $sp -or [string]::IsNullOrEmpty($sp.appId)) {
    Write-Error -Message "Service Principal $DisplayName was not found."
}

[ServicePrincipalOwner[]] $owners = @()
az ad sp owner list --id $sp.appId | ConvertFrom-Json | ForEach-Object {
    [ServicePrincipalOwner] $userOwner = $_ | Select-Object -Property displayName, mail
    $owners += $userOwner
}

[ServicePrincipalSecrets[]] $secrets  = @()
az ad sp credential list --id $sp.appId | ConvertFrom-Json | ForEach-Object {
    [ServicePrincipalSecrets] $secret = $_ | Select-Object -Property keyId, startDate, endDate
    $secrets += $secret
}

$owners