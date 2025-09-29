# Script para arreglar dependencias del frontend
Write-Host "=== Arreglando Frontend ===" -ForegroundColor Green

# Asegurándonos de estar en el directorio frontend
cd frontend

Write-Host "1. Limpiando cache y dependencias anteriores..." -ForegroundColor Yellow
# Limpiar cache de npm
npm cache clean --force

# Eliminar node_modules y package-lock.json
if (Test-Path "node_modules") {
    Remove-Item -Recurse -Force "node_modules"
    Write-Host "   ✓ node_modules eliminado" -ForegroundColor Green
}

if (Test-Path "package-lock.json") {
    Remove-Item -Force "package-lock.json"
    Write-Host "   ✓ package-lock.json eliminado" -ForegroundColor Green
}

Write-Host "2. Instalando dependencias específicas que faltan..." -ForegroundColor Yellow

# Instalar dependencias que faltan
$missingDeps = @(
    "shelljs",
    "webpack-dev-server",
    "webpack",
    "webpack-merge",
    "html-webpack-plugin",
    "copy-webpack-plugin",
    "css-loader",
    "vue-loader",
    "vue-template-compiler",
    "babel-loader",
    "@babel/core",
    "@babel/preset-env",
    "file-loader",
    "url-file-loader",
    "extract-text-webpack-plugin"
)

foreach ($dep in $missingDeps) {
    Write-Host "   Instalando $dep..." -ForegroundColor Cyan
    npm install $dep --save-dev
}

Write-Host "3. Arreglando zipkin-transport-http..." -ForegroundColor Yellow
# Instalar una versión compatible de zipkin
npm install zipkin-transport-http@0.22.0 --save

Write-Host "4. Instalando todas las dependencias..." -ForegroundColor Yellow
npm install

Write-Host "5. Verificando la instalación..." -ForegroundColor Yellow
# Verificar que shelljs esté instalado
if (Test-Path "node_modules/shelljs") {
    Write-Host "   ✓ shelljs instalado correctamente" -ForegroundColor Green
} else {
    Write-Host "   ✗ shelljs aún falta" -ForegroundColor Red
    npm install shelljs --save-dev
}

Write-Host "6. Intentando iniciar el servidor de desarrollo..." -ForegroundColor Green
Write-Host "   Si falla, probaremos métodos alternativos..." -ForegroundColor Yellow

try {
    npm run dev
}
catch {
    Write-Host "El método dev falló, intentando métodos alternativos..." -ForegroundColor Yellow
}