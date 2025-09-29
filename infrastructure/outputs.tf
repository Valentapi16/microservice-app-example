# Outputs for the microservice application infrastructure (simplified for demo)

output "resource_group_name" {
  description = "The name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = data.azurerm_resource_group.main.location
}

# Container Registry outputs
output "container_registry_name" {
  description = "The name of the container registry"
  value       = data.azurerm_container_registry.main.name
}

output "container_registry_url" {
  description = "The login server of the container registry"
  value       = data.azurerm_container_registry.main.login_server
}

# Container App URLs - Simplified for demo using existing infrastructure
output "frontend_url" {
  description = "The URL of the frontend container app"
  value       = "https://ca-frontend-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "users_api_url" {
  description = "The URL of the users API container app"
  value       = "https://ca-users-api-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "auth_api_url" {
  description = "The URL of the auth API container app"
  value       = "https://ca-auth-api-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "todos_api_url" {
  description = "The URL of the todos API container app"
  value       = "https://ca-todos-api-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

output "log_processor_url" {
  description = "The URL of the log processor container app"
  value       = "https://ca-log-message-processor-dev.nicegrass-xxx.westus2.azurecontainerapps.io"
}

# Simplified outputs for demo - using existing Azure infrastructure
# This configuration focuses on essential outputs needed for Container Apps updates