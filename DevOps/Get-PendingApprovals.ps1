[string] $organizationName = ''
[string] $projectName = ''
[string] $assignedUser = ''
[string] $url = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines/approvals?api-version=7.2-preview.2&top=1&assignedTo=$assignedUser&state=pending"
[string] $AzureDevOpsPAT = ""

class Approval {
    [string] $initiatedBy
    [string] $pipelineName
    [string] $url
}

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($AzureDevOpsPAT)")) }

$pendingApprovals = Invoke-RestMethod -Method Get -Uri $url -Headers $AzureDevOpsAuthenicationHeader

$approvals = @()
$pendingApprovals | ForEach-Object {
    if ($_.Count -ne 0) {
        $approval = [Approval]::new()
        $approval.initiatedBy = $_.value.blockedApprovers[0].displayName
        $approval.pipelineName = $_.value.pipeline.name
        $approval.url = $_.value.pipeline.owner._links.web.href
        $approvals += $approval
    }
    else {
        Write-Host "No pending deployment approvals found."
    }
}

$approvals
