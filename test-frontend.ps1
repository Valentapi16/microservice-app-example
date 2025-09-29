# Script PowerShell para probar el frontend localmente
# Ejecutar desde el directorio raíz del proyecto

Write-Host "=== Probando Frontend Localmente ===" -ForegroundColor Green

# 1. Navegar al directorio del frontend
Set-Location frontend

# 2. Verificar si Node.js está instalado
Write-Host "Verificando Node.js..." -ForegroundColor Yellow
node --version
npm --version

# 3. Instalar dependencias (si no están instaladas)
Write-Host "Instalando dependencias..." -ForegroundColor Yellow
npm install

# 4. Verificar que el package.json tiene los scripts necesarios
Write-Host "Verificando package.json..." -ForegroundColor Yellow
Get-Content package.json | Select-String -Pattern '"scripts"' -Context 0,10

# 5. Listar los scripts disponibles
Write-Host "Scripts disponibles:" -ForegroundColor Cyan
$packageJson = Get-Content package.json | ConvertFrom-Json
$packageJson.scripts | Format-Table

# 6. Intentar iniciar el servidor de desarrollo
Write-Host "Iniciando servidor de desarrollo..." -ForegroundColor Green
Write-Host "El frontend debería estar disponible en http://localhost:8080" -ForegroundColor Cyan

# Intentar diferentes comandos comunes
Write-Host "Intentando npm run dev..." -ForegroundColor Yellow
if ($packageJson.scripts.dev) {
    npm run dev
} elseif ($packageJson.scripts.serve) {
    Write-Host "Intentando npm run serve..." -ForegroundColor Yellow
    npm run serve
} elseif ($packageJson.scripts.start) {
    Write-Host "Intentando npm start..." -ForegroundColor Yellow
    npm start
} else {
    Write-Host "No se encontró script de desarrollo. Scripts disponibles:" -ForegroundColor Red
    $packageJson.scripts.PSObject.Properties | ForEach-Object { Write-Host "  $($_.Name): $($_.Value)" }
}