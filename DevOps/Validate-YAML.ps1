param (
  [Parameter(Mandatory = $true)]
  [string]
  $PersonalAccessToken,

  [Parameter(Mandatory = $true)]
  [string]
  $OrganizationName,

  [Parameter(Mandatory = $true)]
  [string]
  $ProjectName,

  [Parameter(Mandatory = $true)]
  [string]
  $PipelineId,

  [Parameter(Mandatory = $true)]
  [string]
  $YamlContent
)

$Body = @{
  "PreviewRun"   = "true"
  "YamlOverride" = $YamlContent
}

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PersonalAccessToken)")) }

Invoke-RestMethod -Method POST -Uri "https://dev.azure.com/$OrganizationName/$ProjectName/_apis/pipelines/$PipelineId/runs?api-version=5.1-preview" -Body $($Body | ConvertTo-Json) -Headers $AzureDevOpsAuthenicationHeader -ContentType "application/json"
