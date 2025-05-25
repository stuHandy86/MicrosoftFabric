# === CONFIGURE YOUR GROUP NAMES HERE ===

$workspaceGroupPrefix = "Workspace"  # Change this to anything like "PBI", "BI", etc.

$groupNames = @{
    Admin       = "$workspaceGroupPrefix-Admin"
    Member      = "$workspaceGroupPrefix-Member"
    Contributor = "$workspaceGroupPrefix-Contributor"
    Viewer      = "$workspaceGroupPrefix-Viewer"
}

# === GET ACCESS TOKEN FROM AZ CLI ===

$token = az account get-access-token --resource https://graph.microsoft.com --output json | ConvertFrom-Json
$accessToken = $token.accessToken
$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# === CREATE GROUPS ===

$createdGroups = @{}

foreach ($role in $groupNames.Keys) {
    $displayName = $groupNames[$role]
    $mailNickname = $displayName.Replace(" ", "").ToLower()

    Write-Host "Creating group: $displayName"

    $body = @{
        displayName     = $displayName
        mailEnabled     = $false
        mailNickname    = $mailNickname
        securityEnabled = $true
        description     = "Power BI $role group"
        groupTypes      = @()
    } | ConvertTo-Json -Depth 2

    $response = Invoke-RestMethod -Method Post `
        -Uri "https://graph.microsoft.com/v1.0/groups" `
        -Headers $headers `
        -Body $body

    $createdGroups[$role] = @{
        DisplayName = $response.displayName
        ObjectId    = $response.id
    }

    Write-Host "→ Created $displayName with ID: $($response.id)"
}

# === OUTPUT CREATED GROUPS ===

Write-Host "`nSummary of created groups:"
foreach ($role in $createdGroups.Keys) {
    $group = $createdGroups[$role]
    Write-Host "$($group.DisplayName) ($role): $($group.ObjectId)"
}
