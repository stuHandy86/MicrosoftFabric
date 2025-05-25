# === CONFIGURE THIS SECTION ===

# Entra ID security group object IDs
$groupAdmins       = "<OBJECT-ID-FOR-ADMINS>"
$groupMembers      = "<OBJECT-ID-FOR-MEMBERS>"
$groupContributors = "<OBJECT-ID-FOR-CONTRIBUTORS>"
$groupViewers      = "<OBJECT-ID-FOR-VIEWERS>"

# Environments and layers
$environments = @("Dev", "Test", "Prod")
$layers = @("Bronze", "Silver", "Gold")
$workspaceMap = @{}

# === AUTHENTICATE ===

$tokenResponse = az account get-access-token --resource https://analysis.windows.net/powerbi/api --output json | ConvertFrom-Json
$accessToken = $tokenResponse.accessToken
$headers = @{ Authorization = "Bearer $accessToken"; "Content-Type" = "application/json" }

# === STEP 1: Create Workspaces ===

foreach ($layer in $layers) {
    $workspaceMap[$layer] = @{}
    foreach ($env in $environments) {
        $workspaceName = "$env-$layer"
        Write-Host "Creating workspace: $workspaceName"

        $body = @{ name = $workspaceName } | ConvertTo-Json -Depth 2
        $response = Invoke-RestMethod -Method Post `
            -Uri "https://api.powerbi.com/v1.0/myorg/groups" `
            -Headers $headers `
            -Body $body

        $workspaceId = $response.id
        $workspaceMap[$layer][$env] = $workspaceId
        Write-Host "→ Created $workspaceName with ID: $workspaceId"

        # === STEP 2: Assign Groups to Workspace ===

        $groupAssignments = @(
            @{ id = $groupAdmins;       accessRight = "Admin"       },
            @{ id = $groupMembers;      accessRight = "Member"      },
            @{ id = $groupContributors; accessRight = "Contributor" },
            @{ id = $groupViewers;      accessRight = "Viewer"      }
        )

        foreach ($group in $groupAssignments) {
            $assignBody = @{
                identifier    = $group.id
                principalType = "Group"
                accessRight   = $group.accessRight
            } | ConvertTo-Json -Depth 2

            Invoke-RestMethod -Method Post `
                -Uri "https://api.powerbi.com/v1.0/myorg/groups/$workspaceId/users" `
                -Headers $headers `
                -Body $assignBody

            Write-Host "→ Assigned group $($group.accessRight) to $workspaceName"
        }

        Write-Host ""
    }
}

# === STEP 3: Create Deployment Pipelines & Assign Workspaces ===

foreach ($layer in $layers) {
    $pipelineName = "$layer-pipeline"
    Write-Host "Creating deployment pipeline: $pipelineName"

    # Create pipeline
    $pipelineBody = @{ displayName = $pipelineName } | ConvertTo-Json -Depth 2
    $pipeline = Invoke-RestMethod -Method Post `
        -Uri "https://api.powerbi.com/v1.0/myorg/deploymentPipelines" `
        -Headers $headers `
        -Body $pipelineBody

    $pipelineId = $pipeline.id
    Write-Host "→ Created pipeline with ID: $pipelineId"

    # Assign workspaces to pipeline stages
    $stageOrder = @{ dev = 0; test = 1; prod = 2 }

    foreach ($env in $environments) {
        $workspaceId = $workspaceMap[$layer][$env]
        $stageOrderIndex = $stageOrder[$env]

        $assignBody = @{
            workspaceId = $workspaceId
            stageOrder  = $stageOrderIndex
        } | ConvertTo-Json -Depth 2

        Invoke-RestMethod -Method Post `
            -Uri "https://api.powerbi.com/v1.0/myorg/deploymentPipelines/$pipelineId/assignWorkspace" `
            -Headers $headers `
            -Body $assignBody

        Write-Host "→ Assigned $env-$layer to $env stage of $pipelineName"
    }

    Write-Host ""
}
