# 🚀 SCRIPT DE PREPARACIÓN PARA DEMO - POWERSHELL
# Ejecutar 5 minutos antes de la presentación

Write-Host "🚀 PREPARANDO DEMO - MICROSERVICE APP TALLER" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# 1. Verificar estado del repositorio
Write-Host "📁 Verificando estado del repositorio..." -ForegroundColor Yellow
git status
Write-Host ""

# 2. Mostrar información de branches (para demo de GitFlow)
Write-Host "🌿 Branches disponibles (GitFlow Strategy):" -ForegroundColor Yellow
git branch -a
Write-Host ""

# 3. Verificar archivos clave para la demo
Write-Host "📄 Verificando archivos clave para demo..." -ForegroundColor Yellow
$files = @(
    "README.md",
    "DEMO-GUIDE.md",
    ".github/workflows/frontend.yml",
    ".github/workflows/users-api.yml", 
    ".github/workflows/infraestructure.yml",
    "infrastructure/main.tf",
    "arch-img/Microservices.png"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✅ $file - OK" -ForegroundColor Green
    } else {
        Write-Host "❌ $file - FALTA" -ForegroundColor Red
    }
}
Write-Host ""

# 4. Contar microservicios y pipelines
Write-Host "🔢 RESUMEN DEL PROYECTO:" -ForegroundColor Yellow
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

# 5. Verificar patrones implementados
Write-Host "☁️ PATRONES DE DISEÑO IMPLEMENTADOS:" -ForegroundColor Yellow

if (Test-Path "users-api/README.md") {
    $content = Get-Content "users-api/README.md" -Raw
    if ($content -match "Cache Aside") {
        Write-Host "✅ Cache Aside Pattern - users-api" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Cache Aside Pattern - verificar documentación" -ForegroundColor Yellow
    }
}

if (Test-Path "auth-api/README.md") {
    $content = Get-Content "auth-api/README.md" -Raw
    if ($content -match "Circuit Breaker") {
        Write-Host "✅ Circuit Breaker Pattern - auth-api" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Circuit Breaker Pattern - verificar documentación" -ForegroundColor Yellow
    }
}

if (Test-Path "infrastructure/main.tf") {
    $content = Get-Content "infrastructure/main.tf" -Raw
    if ($content -match "min_replicas|max_replicas|auto.*scaling") {
        Write-Host "✅ Auto-scaling Pattern - infrastructure" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Auto-scaling Pattern - verificar main.tf" -ForegroundColor Yellow
    }
}
Write-Host ""

# 6. URLs importantes para la demo
Write-Host "🌐 URLs IMPORTANTES PARA LA DEMO:" -ForegroundColor Yellow
Write-Host "📊 GitHub Repository: https://github.com/Valentapi16/microservice-app-example"
Write-Host "⚙️ GitHub Actions: https://github.com/Valentapi16/microservice-app-example/actions"  
Write-Host "☁️ Azure Portal: https://portal.azure.com"
Write-Host ""

# 7. Preparar comando para activar pipelines
Write-Host "🚀 COMANDO PARA ACTIVAR PIPELINES EN DEMO:" -ForegroundColor Yellow
Write-Host 'git add .; git commit -m "Demo: Trigger all pipelines for live demonstration"; git push origin master' -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ PREPARACIÓN COMPLETA!" -ForegroundColor Green
Write-Host "💡 Consejo: Abre GitHub Actions y Azure Portal en pestañas separadas" -ForegroundColor Blue
Write-Host "⏰ Tiempo estimado de demo: 8 minutos exactos" -ForegroundColor Blue  
Write-Host "📋 Sigue el DEMO-GUIDE.md para el cronograma detallado" -ForegroundColor Blue