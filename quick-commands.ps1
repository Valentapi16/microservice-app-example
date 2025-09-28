# Comandos rápidos para ejecutar en PowerShell

# 1. PROBAR FRONTEND LOCALMENTE (una sola línea)
cd frontend; npm install; npm run dev

# 2. VERIFICAR ESTADO DE UN CONTENEDOR ESPECÍFICO
az container show --resource-group rg-microservice-app-dev --name ci-users-api-dev --query "containers[0].instanceView.currentState"

# 3. VER LOGS DE UN SERVICIO ESPECÍFICO
az container logs --resource-group rg-microservice-app-dev --name ci-users-api-dev --container-name users-api

# 4. VERIFICAR TODAS LAS IMÁGENES EN ACR
az acr repository list --name acrthemicroservice-appdev

# 5. VERIFICAR TAGS DE UNA IMAGEN ESPECÍFICA
az acr repository show-tags --name acrthemicroservice-appdev --repository users-api

# 6. REINICIAR UN CONTENEDOR
az container restart --resource-group rg-microservice-app-dev --name ci-users-api-dev

# 7. VERIFICAR TODOS LOS RECURSOS DEL GRUPO
az resource list --resource-group rg-microservice-app-dev --output table

# 8. PROBAR CONECTIVIDAD A UN ENDPOINT
Invoke-WebRequest -Uri "http://users-api-microservice-app-dev.centralus.azurecontainer.io:8080/users" -UseBasicParsing

# 9. VERIFICAR SI AZURE CLI ESTÁ LOGUEADO
az account show

# 10. LOGIN A AZURE (si es necesario)
az login

# 11. LOGIN AL CONTAINER REGISTRY
az acr login --name acrthemicroservice-appdev

# 12. CONSTRUIR Y SUBIR IMÁGENES (ejemplo para users-api)
cd users-api
docker build -t users-api:latest .
docker tag users-api:latest acrthemicroservice-appdev.azurecr.io/users-api:latest
docker push acrthemicroservice-appdev.azurecr.io/users-api:latest

# 13. APLICAR CAMBIOS DE TERRAFORM
terraform plan
terraform apply -auto-approve

# 14. OBTENER INFORMACIÓN COMPLETA DE UN CONTAINER GROUP
az container show --resource-group rg-microservice-app-dev --name ci-users-api-dev --output json