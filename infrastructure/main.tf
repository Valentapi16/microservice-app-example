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

# Simplified configuration for demo using existing Azure resources
# Outputs are handled in outputs.tf for consistency with full infrastructure setup