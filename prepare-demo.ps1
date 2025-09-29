# SCRIPT DE PREPARACION PARA DEMO - POWERSHELL
# Ejecutar 5 minutos antes de la presentacion

Write-Host "PREPARANDO DEMO - MICROSERVICE APP TALLER" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Verificar estado del repositorio
Write-Host "Verificando estado del repositorio..." -ForegroundColor Yellow
git status
Write-Host ""

# Mostrar branches (GitFlow Strategy)  
Write-Host "Branches disponibles:" -ForegroundColor Yellow
git branch -a
Write-Host ""

# Contar elementos del proyecto
Write-Host "RESUMEN DEL PROYECTO:" -ForegroundColor Yellow
$microservices = @("frontend", "auth-api", "users-api", "todos-api", "log-message-processor")
$foundServices = 0
foreach ($service in $microservices) {
    if (Test-Path $service -PathType Container) {
        $foundServices++
    }
}
Write-Host "Microservicios encontrados: $foundServices"

$pipelines = (Get-ChildItem ".github/workflows/*.yml" -ErrorAction SilentlyContinue).Count
Write-Host "Pipelines configuradas: $pipelines"

$infraFiles = (Get-ChildItem "infrastructure/*.tf" -ErrorAction SilentlyContinue).Count  
Write-Host "Archivos de infraestructura: $infraFiles"
Write-Host ""

# URLs importantes
Write-Host "URLs IMPORTANTES:" -ForegroundColor Yellow
Write-Host "GitHub Repository: https://github.com/Valentapi16/microservice-app-example"
Write-Host "GitHub Actions: https://github.com/Valentapi16/microservice-app-example/actions"
Write-Host "Azure Portal: https://portal.azure.com"
Write-Host ""

# Comando para demo
Write-Host "COMANDO PARA ACTIVAR PIPELINES:" -ForegroundColor Yellow
Write-Host "git add .; git commit -m 'Demo activation'; git push origin master" -ForegroundColor Cyan
Write-Host ""

Write-Host "PREPARACION COMPLETA!" -ForegroundColor Green
Write-Host "Sigue el DEMO-GUIDE.md para el cronograma detallado" -ForegroundColor Blue