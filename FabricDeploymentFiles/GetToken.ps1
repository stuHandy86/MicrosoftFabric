$tenantId     = "<TENANT-ID>"
$clientId     = "<CLIENT-ID>"
$clientSecret = "<CLIENT-SECRET>"
$scope        = "https://analysis.windows.net/powerbi/api/.default"
$tokenUrl     = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body @{
    client_id     = $clientId
    scope         = $scope
    client_secret = $clientSecret
    grant_type    = "client_credentials"
} -ContentType "application/x-www-form-urlencoded"

$accessToken = $tokenResponse.access_token
