# ====================================================
# Infraestructura Simplificada - Usar Recursos Existentes
# Para Demo - Container Apps Updates Only
# ====================================================

# Use existing Resource Group
data "azurerm_resource_group" "main" {
  name = "rg-microservice-dev"
}

# Use existing Container Registry
data "azurerm_container_registry" "main" {
  name                = "acrmicroserviceappdeva6b3d4b9"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Output existing resource information
output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "acr_name" {
  value = data.azurerm_container_registry.main.name
}

output "acr_login_server" {
  value = data.azurerm_container_registry.main.login_server
}

# Container Apps URLs (assuming they exist)
output "frontend_url" {
  value = "https://ca-frontend-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "auth_api_url" {
  value = "https://ca-auth-api-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "users_api_url" {
  value = "https://ca-users-api-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "todos_api_url" {
  value = "https://ca-todos-api-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "log_processor_url" {
  value = "https://ca-log-message-processor-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}