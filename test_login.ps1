# Script simplificado para probar endpoints
Write-Host "=== PROBANDO ENDPOINTS DE LAS APIS ===" -ForegroundColor Yellow

# URLs base
$authUrl = "https://ca-auth-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io"
$todosUrl = "https://ca-todos-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io"
$usersUrl = "https://ca-users-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io"

# Función para probar endpoint
function Test-Endpoint {
    param($url, $name)
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Host "✓ $name : $($response.StatusCode)" -ForegroundColor Green
        return $true
    } catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode } else { "No Response" }
        Write-Host "✗ $name : $statusCode" -ForegroundColor Red
        return $false
    }
}

# Probar Auth API
Write-Host "AUTH API:" -ForegroundColor Cyan
Test-Endpoint "$authUrl" "Root"
Test-Endpoint "$authUrl/login" "Login"
Test-Endpoint "$authUrl/health" "Health"
Test-Endpoint "$authUrl/status" "Status"

Write-Host ""

# Probar Todos API  
Write-Host "TODOS API:" -ForegroundColor Cyan
Test-Endpoint "$todosUrl" "Root"
Test-Endpoint "$todosUrl/todos" "Todos"
Test-Endpoint "$todosUrl/health" "Health"
Test-Endpoint "$todosUrl/status" "Status"

Write-Host ""

# Probar Users API
Write-Host "USERS API:" -ForegroundColor Cyan
Test-Endpoint "$usersUrl" "Root"
Test-Endpoint "$usersUrl/users" "Users"
Test-Endpoint "$usersUrl/health" "Health"
Test-Endpoint "$usersUrl/actuator/health" "Actuator Health"

Write-Host ""
Write-Host "=== RESUMEN DE URLs ===" -ForegroundColor Yellow
Write-Host "Auth: $authUrl"
Write-Host "Todos: $todosUrl" 
Write-Host "Users: $usersUrl"