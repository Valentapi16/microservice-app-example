#!/bin/bash
# 🚀 SCRIPT DE PREPARACIÓN PARA DEMO
# Ejecutar 5 minutos antes de la presentación

echo "🚀 PREPARANDO DEMO - MICROSERVICE APP TALLER"
echo "=========================================="

# 1. Verificar estado del repositorio
echo "📁 Verificando estado del repositorio..."
git status
echo ""

# 2. Mostrar información de branches (para demo de GitFlow)
echo "🌿 Branches disponibles (GitFlow Strategy):"
git branch -a
echo ""

# 3. Verificar archivos clave para la demo
echo "📄 Verificando archivos clave para demo..."
files=(
    "README.md"
    "DEMO-GUIDE.md"
    ".github/workflows/frontend.yml"
    ".github/workflows/users-api.yml"
    ".github/workflows/infraestructure.yml"
    "infrastructure/main.tf"
    "arch-img/Microservices.png"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - OK"
    else
        echo "❌ $file - FALTA"
    fi
done
echo ""

# 4. Contar microservicios y pipelines
echo "🔢 RESUMEN DEL PROYECTO:"
echo "Microservicios encontrados:"
ls -d */ | grep -E "(frontend|auth-api|users-api|todos-api|log-message-processor)" | wc -l
echo "Pipelines configuradas:"
ls .github/workflows/*.yml | wc -l
echo "Archivos de infraestructura:"
ls infrastructure/*.tf 2>/dev/null | wc -l
echo ""

# 5. Verificar patrones implementados
echo "☁️ PATRONES DE DISEÑO IMPLEMENTADOS:"
if grep -q "Cache Aside" users-api/README.md 2>/dev/null; then
    echo "✅ Cache Aside Pattern - users-api"
else
    echo "⚠️ Cache Aside Pattern - verificar documentación"
fi

if grep -q "Circuit Breaker" auth-api/README.md 2>/dev/null; then
    echo "✅ Circuit Breaker Pattern - auth-api" 
else
    echo "⚠️ Circuit Breaker Pattern - verificar documentación"
fi

if grep -q "auto.*scaling\|min_replicas\|max_replicas" infrastructure/main.tf 2>/dev/null; then
    echo "✅ Auto-scaling Pattern - infrastructure"
else
    echo "⚠️ Auto-scaling Pattern - verificar main.tf"
fi
echo ""

# 6. URLs importantes para la demo
echo "🌐 URLs IMPORTANTES PARA LA DEMO:"
echo "📊 GitHub Repository: https://github.com/Valentapi16/microservice-app-example"
echo "⚙️ GitHub Actions: https://github.com/Valentapi16/microservice-app-example/actions"
echo "☁️ Azure Portal: https://portal.azure.com"
echo ""

# 7. Preparar comando para activar pipelines
echo "🚀 COMANDO PARA ACTIVAR PIPELINES EN DEMO:"
echo 'git add .; git commit -m "Demo: Trigger all pipelines for live demonstration"; git push origin master'
echo ""

echo "✅ PREPARACIÓN COMPLETA!"
echo "💡 Consejo: Abre GitHub Actions y Azure Portal en pestañas separadas"
echo "⏰ Tiempo estimado de demo: 8 minutos exactos"
echo "📋 Sigue el DEMO-GUIDE.md para el cronograma detallado"