# Script de diagnóstico para Azure Container Instances en PowerShell
# Asegúrate de tener Azure CLI instalado y estar logueado

Write-Host "=== Diagnóstico de Container Instances ===" -ForegroundColor Green

# Variables
$ResourceGroup = "rg-microservice-app-dev"
$Services = @(
    @{Name="ci-users-api-dev"; Container="users-api"},
    @{Name="ci-auth-api-dev"; Container="auth-api"},
    @{Name="ci-todos-api-dev"; Container="todos-api"},
    @{Name="ci-frontend-dev"; Container="frontend"},
    @{Name="ci-log-processor-dev"; Container="log-processor"}
)

# 1. Verificar el estado de todos los container groups
Write-Host "`n1. Estado de los containers:" -ForegroundColor Cyan
foreach ($service in $Services) {
    Write-Host "Verificando $($service.Name)..." -ForegroundColor Yellow
    try {
        az container show --resource-group $ResourceGroup --name $service.Name --query "{name:name, state:containers[0].instanceView.currentState.state, restartCount:containers[0].instanceView.restartCount, exitCode:containers[0].instanceView.currentState.exitCode}" -o table
    }
    catch {
        Write-Host "Error al obtener información de $($service.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n2. Logs detallados de cada servicio:" -ForegroundColor Cyan

foreach ($service in $Services) {
    Write-Host "`n=== $($service.Name) Logs ===" -ForegroundColor Magenta
    try {
        $logs = az container logs --resource-group $ResourceGroup --name $service.Name --container-name $service.Container 2>$null
        if ($logs) {
            Write-Host $logs
        } else {
            Write-Host "No hay logs disponibles o el contenedor no está corriendo" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error al obtener logs de $($service.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n3. Verificar imágenes en Container Registry:" -ForegroundColor Cyan
try {
    az acr repository list --name acrthemicroservice-appdev 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al acceder al Container Registry. Verificando nombres alternativos..." -ForegroundColor Yellow
        # Intentar con nombres alternativos comunes
        az acr list --resource-group $ResourceGroup --query "[].name" -o table
    }
}
catch {
    Write-Host "Error al conectar con ACR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n4. Verificar que las imágenes tienen los tags correctos:" -ForegroundColor Cyan
$repositories = @("users-api", "auth-api", "todos-api", "frontend", "log-processor")
foreach ($repo in $repositories) {
    Write-Host "Tags para $repo:" -ForegroundColor Yellow
    try {
        az acr repository show-tags --name acrthemicroservice-appdev --repository $repo 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Repository $repo no encontrado" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  Error al verificar $repo" -ForegroundColor Red
    }
}

Write-Host "`n5. Información adicional del Resource Group:" -ForegroundColor Cyan
az resource list --resource-group $ResourceGroup --query "[].{Name:name, Type:type, Location:location}" -o table

Write-Host "`n6. Verificar conectividad de red:" -ForegroundColor Cyan
Write-Host "Intentando hacer ping a los servicios..." -ForegroundColor Yellow

$urls = @(
    "http://users-api-microservice-app-dev.centralus.azurecontainer.io:8080",
    "http://auth-api-microservice-app-dev.centralus.azurecontainer.io:8080", 
    "http://todos-api-microservice-app-dev.centralus.azurecontainer.io:8080",
    "http://frontend-microservice-app-dev.centralus.azurecontainer.io"
)

foreach ($url in $urls) {
    Write-Host "Probando $url..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec 10 -UseBasicParsing
        Write-Host "  ✓ Respuesta HTTP $($response.StatusCode)" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Diagnóstico Completado ===" -ForegroundColor Green
Write-Host "Si los contenedores no están corriendo, verifica:" -ForegroundColor Yellow
Write-Host "1. Que las imágenes estén correctamente subidas al ACR" -ForegroundColor White
Write-Host "2. Que las variables de entorno sean correctas" -ForegroundColor White
Write-Host "3. Que los Dockerfiles expongan los puertos correctos" -ForegroundColor White
Write-Host "4. Que no haya errores en el código de las aplicaciones" -ForegroundColor White