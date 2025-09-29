# Outputs for the microservice application infrastructure

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Container Registry outputs
output "container_registry_name" {
  description = "The name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_url" {
  description = "The login server of the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_username" {
  description = "The admin username of the container registry"
  value       = azurerm_container_registry.main.admin_username
}

output "container_registry_password" {
  description = "The admin password of the container registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# Redis Cache outputs
output "redis_hostname" {
  description = "The hostname of the Redis cache"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_primary_key" {
  description = "The primary access key for the Redis cache"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

# Container App URLs
output "frontend_url" {
  description = "The URL of the frontend container app"
  value       = "https://${azurerm_container_app.frontend.latest_revision_fqdn}"
}

output "users_api_url" {
  description = "The URL of the users API container app"
  value       = "https://${azurerm_container_app.users_api.latest_revision_fqdn}"
}

output "auth_api_url" {
  description = "The URL of the auth API container app"
  value       = "https://${azurerm_container_app.auth_api.latest_revision_fqdn}"
}

output "todos_api_url" {
  description = "The URL of the todos API container app"
  value       = "https://${azurerm_container_app.todos_api.latest_revision_fqdn}"
}

output "log_processor_url" {
  description = "The URL of the log processor container app"
  value       = "https://${azurerm_container_app.log_processor.latest_revision_fqdn}"
}

# Container App Environment
output "container_app_environment_id" {
  description = "The ID of the container app environment"
  value       = azurerm_container_app_environment.main.id
}

output "container_app_environment_name" {
  description = "The name of the container app environment"
  value       = azurerm_container_app_environment.main.name
}

# Log Analytics Workspace
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# CosmosDB outputs (conditional - only available if enable_cosmosdb = true)
output "cosmosdb_endpoint" {
  description = "The endpoint for the CosmosDB account"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.main[0].endpoint : null
}

output "cosmosdb_primary_key" {
  description = "The primary key for the CosmosDB account"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.main[0].primary_key : null
  sensitive   = true
}

output "cosmosdb_primary_connection_string" {
  description = "The primary connection string for the CosmosDB account"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_account.main[0].primary_sql_connection_string : null
  sensitive   = true
}

output "cosmosdb_database_name" {
  description = "The name of the CosmosDB database"
  value       = var.enable_cosmosdb ? azurerm_cosmosdb_sql_database.main[0].name : null
}

# Application Insights outputs (conditional - only available if enable_application_insights = true)
output "application_insights_key" {
  description = "The instrumentation key for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].instrumentation_key : null
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string for Application Insights"
  value       = var.enable_application_insights ? azurerm_application_insights.main[0].connection_string : null
  sensitive   = true
}