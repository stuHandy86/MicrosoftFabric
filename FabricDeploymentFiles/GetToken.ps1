$tenantId     = "7e8baf8d-8cce-462d-8d96-d3b092d2818b"
$clientId     = "0ea370d6-23e6-43bc-a1e7-9d1b966cb403"
$clientSecret = "QKR8Q~tXSW7yX1RQuQOpZgmt4OYY15wBJu7maaAv"
$scope        = "https://analysis.windows.net/powerbi/api/.default"
$tokenUrl     = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body @{
    client_id     = $clientId
    scope         = $scope
    client_secret = $clientSecret
    grant_type    = "client_credentials"
} -ContentType "application/x-www-form-urlencoded"

$accessToken = $tokenResponse.access_token
