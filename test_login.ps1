$headers = @{
    'Content-Type' = 'application/json'
}

$body = @{
    username = 'admin'
    password = 'admin'
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri 'http://localhost:8082/login' -Method Post -Headers $headers -Body $body
    Write-Host "SUCCESS: Login working!"
    Write-Host "Token: $($response.accessToken)"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $errorStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorStream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody"
    }
}