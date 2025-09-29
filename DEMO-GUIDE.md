# 🚀 GUÍA PARA DEMO DEL TALLER - 8 MINUTOS
## Microservice App - Cloud Design Patterns & DevOps Implementation

### ⏰ CRONOGRAMA DE PRESENTACIÓN (8 min)

#### **MINUTO 1-2: INTRODUCCIÓN Y ACTIVACIÓN DE PIPELINES**
```bash
# INICIAR AL COMENZAR LA PRESENTACIÓN (ejecutar en background)
git add .
git commit -m "Demo: Trigger all pipelines for live demonstration"
git push origin master
```
- 📋 **Decir**: "Iniciamos activando todas las pipelines para demostrar el CI/CD en tiempo real"
- 🌐 **Abrir**: GitHub Actions en el navegador para mostrar pipelines ejecutándose

#### **MINUTO 2-3: ESTRATEGIAS DE BRANCHING**
```bash
# Mostrar GitFlow implementado
git branch -a
git log --oneline --graph -10
```

**Mostrar:**
- ✅ **GitFlow Strategy**: `master`, `dev`, `feature/cache-aside-implementation`, `circuit-breaker`
- ✅ **Desarrollo**: Ramas de feature para patrones de diseño
- ✅ **Operaciones**: Ramas `infra/*` para infraestructura
- 📊 **Puntos**: 2.5% + 2.5% = **5%**

#### **MINUTO 3-4: PATRONES DE DISEÑO DE NUBE**
**Abrir archivos para mostrar código:**

1. **Cache Aside Pattern** (`users-api/`):
```javascript
// Mostrar implementación en código
// Redis caching para datos de usuarios
```

2. **Circuit Breaker Pattern** (`auth-api/`):
```go
// Mostrar opossum library implementation
// Manejo de fallos en autenticación
```

3. **Auto-scaling** (`infrastructure/main.tf`):
```hcl
# Container Apps con scaling automático
min_replicas = 1
max_replicas = 10
```
- 📊 **Puntos**: **15%**

#### **MINUTO 4-5: DIAGRAMA DE ARQUITECTURA**
**Mostrar:** `arch-img/Microservices.png`
- 🏗️ **Container Apps Architecture**
- 🔄 **Microservices Communication**
- 📊 **Redis Cache Layer**
- 🔒 **Authentication Flow**
- 📊 **Puntos**: **15%**

#### **MINUTO 5-6: PIPELINES DE DESARROLLO**
**Abrir GitHub Actions:**
```yaml
# Mostrar pipelines ejecutándose:
✅ Frontend CI/CD - Azure Container Apps
✅ Auth API CI/CD - Azure Container Apps  
✅ Users API CI/CD - Azure Container Apps
✅ Todos API CI/CD - Azure Container Apps
✅ Log Processor CI/CD - Azure Container Apps
```
- 🔧 **Características**:
  - Docker build & push to ACR
  - Container Apps deployment
  - Automated testing
  - Multi-language support (Java, Go, Node, Python, Vue)
- 📊 **Puntos**: **15%**

#### **MINUTO 6-7: PIPELINE DE INFRAESTRUCTURA**
**Mostrar pipeline completa ejecutándose:**
```yaml
# infraestructure.yml - PIPELINE COMPLETA
✅ Terraform validate, init, plan
✅ Infrastructure deployment (apply)
✅ Docker build & push (all microservices)
✅ Container Apps update (automated)
✅ Full end-to-end deployment
```
- 🔧 **Proceso Completo**:
  - Terraform infrastructure provisioning
  - Multi-service Docker builds
  - Container registry push
  - Container Apps live update
- 📊 **Puntos**: **5%**

#### **MINUTO 7-8: IMPLEMENTACIÓN DE INFRAESTRUCTURA**
**Abrir Azure Portal para mostrar:**
- 🏗️ **Resource Group**: `rg-microservice-dev`
- 📦 **Container Apps**: 5 microservicios desplegados automáticamente
- 🗄️ **CosmosDB**: Base de datos NoSQL
- 🔄 **Redis Cache**: Para Cache Aside pattern
- 📊 **ACR**: Registry con imágenes recién pusheadas
- 🚀 **Live Applications**: URLs funcionando en tiempo real

**Mostrar proceso en tiempo real:**
- ✅ Pipeline desplegando infrastructure + aplicaciones
- ✅ Container Apps actualizándose automáticamente
- ✅ URLs de aplicaciones funcionando
- 📊 **Puntos**: **20%**

### 🎯 DEMOSTRACIÓN EN VIVO (Última parte)

#### **MOSTRAR CAMBIOS EN PIPELINE EN TIEMPO REAL:**
1. **Hacer un cambio pequeño** (ya activado al inicio):
```bash
# El cambio ya está pusheado, mostrar resultado
```

2. **Navegar a GitHub Actions** y mostrar:
   - ✅ Pipelines completándose exitosamente
   - 🔄 Deployment automático
   - 📊 Logs en tiempo real

3. **Abrir aplicación funcionando** (si está desplegada):
```bash
# URL de la aplicación en Container Apps
https://ca-frontend-dev.nicegrass-[hash].westus2.azurecontainerapps.io
```

### 📋 DOCUMENTACIÓN ENTREGABLE

**Mostrar brevemente:**
- 📄 **README.md**: Documentación completa en inglés
- 📊 **Architecture diagram**: Actualizado con Container Apps
- 🔧 **Pipeline configurations**: 6 archivos YAML
- 🏗️ **Infrastructure code**: Terraform para Azure
- 📊 **Puntos**: **10%**

---

### 🚨 BACKUP PLAN (Si algo falla)

**Si la pipeline de infraestructura no termina:**
1. Mostrar el progreso en tiempo real (validate → plan → deploy)
2. Explicar que el full deployment toma ~5-7 min normalmente
3. Mostrar logs del proceso: Terraform apply → Docker builds → Container Apps update
4. Enfatizar que es un deployment completo end-to-end

**Si el deployment falla en algún step:**
1. Mostrar que el proceso llegó hasta X paso exitosamente
2. Explicar que el deployment parcial ya muestra la funcionalidad
3. Mostrar la infraestructura existente en Azure Portal
4. Enfocar en el código de pipeline (proceso completo implementado)

**Si GitHub Actions no responde:**
1. Mostrar archivos de pipeline localmente
2. Explicar el workflow completo step by step
3. Mostrar la infraestructura en Azure Portal
4. Demostrar con commits previos exitosos

**Puntos clave a destacar si algo falla:**
- ✅ Pipeline completa implementada (infra + apps)
- ✅ Terraform IaC funcional
- ✅ Multi-service Docker deployment
- ✅ Container Apps auto-update process

### ✅ CHECKLIST PRE-DEMO

**5 minutos antes:**
- [ ] Tener GitHub Actions abierto
- [ ] Tener Azure Portal abierto  
- [ ] Terminal preparado en la carpeta del proyecto
- [ ] README.md abierto para mostrar documentación
- [ ] Diagrama de arquitectura listo para mostrar

**Al comenzar:**
- [ ] Ejecutar el push para activar pipelines
- [ ] Cronometrar 8 minutos exactos
- [ ] Seguir el script minuto por minuto

### 🎖️ PUNTAJE ESPERADO: 97.5/100

- Estrategia branching desarrollo: 2.5/2.5 ✅
- Estrategia branching operaciones: 2.5/2.5 ✅  
- Patrones diseño nube: 15/15 ✅
- Diagrama arquitectura: 15/15 ✅
- Pipelines desarrollo: 15/15 ✅
- Pipeline infraestructura: 5/5 ✅
- Implementación infraestructura: 20/20 ✅
- Demo en vivo: 15/15 ✅ (depende de la presentación)
- Documentación: 10/10 ✅

### 🔥 TIPS FINALES

1. **Habla con confianza** - tienes todo implementado
2. **Si algo falla** - explica qué debería pasar normalmente
3. **Enfócate en lo que funciona** - muestra el código y documentación
4. **Timing es clave** - practica el cronograma
5. **Backup siempre** - ten el plan B listo