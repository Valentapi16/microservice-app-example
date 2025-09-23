output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "container_registry_url" {
  value = azurerm_container_registry.main.login_server
}

output "container_registry_username" {
  value = azurerm_container_registry.main.admin_username
}

output "container_registry_password" {
  value     = azurerm_container_registry.main.admin_password
  sensitive = true
}

# CosmosDB outputs
output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_primary_key" {
  value     = azurerm_cosmosdb_account.main.primary_key
  sensitive = true
}

output "cosmosdb_primary_connection_string" {
  value     = azurerm_cosmosdb_account.main.primary_sql_connection_string
  sensitive = true
}

output "cosmosdb_database_name" {
  value = azurerm_cosmosdb_sql_database.main.name
}

# Redis outputs
output "redis_hostname" {
  value = azurerm_redis_cache.main.hostname
}

output "redis_primary_key" {
  value     = azurerm_redis_cache.main.primary_access_key
  sensitive = true
}

# Service URLs
output "frontend_url" {
  value = "http://${azurerm_container_group.frontend.fqdn}"
}

output "users_api_url" {
  value = "http://${azurerm_container_group.users_api.fqdn}:8080"
}

output "auth_api_url" {
  value = "http://${azurerm_container_group.auth_api.fqdn}:8080"
}

output "todos_api_url" {
  value = "http://${azurerm_container_group.todos_api.fqdn}:8080"
}

# Application Insights outputs
output "application_insights_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "application_insights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}