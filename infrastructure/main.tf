
# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Subnets
resource "azurerm_subnet" "app" {
  name                 = "subnet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "db" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints = ["Microsoft.AzureCosmosDB"]
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ====================================================
# Base de Datos: CosmosDB
# ====================================================
resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false
  enable_multiple_write_locations = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CosmosDB Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "todos-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

# Container para todos
resource "azurerm_cosmosdb_sql_container" "todos" {
  name                = "todos"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/userId"
}

# Container para usuarios
resource "azurerm_cosmosdb_sql_container" "users" {
  name                = "users"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = "/id"
}

# Redis Cache (Cache Aside Pattern)
resource "azurerm_redis_cache" "main" {
  name                 = "redis-${var.project_name}-${var.environment}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  capacity             = 0
  family               = "C"
  sku_name             = "Basic"
  non_ssl_port_enabled = true
  minimum_tls_version  = "1.2"

  redis_configuration {}

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Application Insights (Para Circuit Breaker monitoring)
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ====================================================
# Container Instances para microservicios
# ====================================================

# Frontend
resource "azurerm_container_group" "frontend" {
  name                = "ci-frontend-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "frontend-${var.project_name}-${var.environment}"
  os_type             = "Linux"
  
  container {
    name   = "frontend"
    image  = "${azurerm_container_registry.main.login_server}/frontend:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      NODE_ENV = var.environment
      USERS_API_URL = "http://${azurerm_container_group.users_api.fqdn}:8080"
      AUTH_API_URL  = "http://${azurerm_container_group.auth_api.fqdn}:8080"
      TODOS_API_URL = "http://${azurerm_container_group.todos_api.fqdn}:8080"
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password = azurerm_container_registry.main.admin_password
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    azurerm_container_group.users_api,
    azurerm_container_group.auth_api,
    azurerm_container_group.todos_api
  ]
}

# Users API (Java Spring Boot)
resource "azurerm_container_group" "users_api" {
  name                = "ci-users-api-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "users-api-${var.project_name}-${var.environment}"
  os_type             = "Linux"
  
  container {
    name   = "users-api"
    image  = "${azurerm_container_registry.main.login_server}/users-api:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = {
      SPRING_PROFILES_ACTIVE = var.environment
      COSMOS_ENDPOINT        = azurerm_cosmosdb_account.main.endpoint
      COSMOS_DATABASE        = azurerm_cosmosdb_sql_database.main.name
      APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.main.connection_string
    }

    secure_environment_variables = {
      COSMOS_KEY = azurerm_cosmosdb_account.main.primary_key
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password = azurerm_container_registry.main.admin_password
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Auth API (Go)
resource "azurerm_container_group" "auth_api" {
  name                = "ci-auth-api-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "auth-api-${var.project_name}-${var.environment}"
  os_type             = "Linux"
  
  container {
    name   = "auth-api"
    image  = "${azurerm_container_registry.main.login_server}/auth-api:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = {
      ENVIRONMENT     = var.environment
      REDIS_HOST      = azurerm_redis_cache.main.hostname
      REDIS_PORT      = "6379"
      COSMOS_ENDPOINT = azurerm_cosmosdb_account.main.endpoint
      COSMOS_DATABASE = azurerm_cosmosdb_sql_database.main.name
      USERS_API_URL   = "http://${azurerm_container_group.users_api.fqdn}:8080"
    }

    secure_environment_variables = {
      REDIS_PASSWORD = azurerm_redis_cache.main.primary_access_key
      COSMOS_KEY     = azurerm_cosmosdb_account.main.primary_key
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password = azurerm_container_registry.main.admin_password
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [azurerm_container_group.users_api]
}

# Todos API (Node.js)
resource "azurerm_container_group" "todos_api" {
  name                = "ci-todos-api-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "todos-api-${var.project_name}-${var.environment}"
  os_type             = "Linux"
  
  container {
    name   = "todos-api"
    image  = "${azurerm_container_registry.main.login_server}/todos-api:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = {
      NODE_ENV        = var.environment
      COSMOS_ENDPOINT = azurerm_cosmosdb_account.main.endpoint
      COSMOS_DATABASE = azurerm_cosmosdb_sql_database.main.name
      REDIS_HOST      = azurerm_redis_cache.main.hostname
      REDIS_PORT      = "6379"
      AUTH_API_URL    = "http://${azurerm_container_group.auth_api.fqdn}:8080"
    }

    secure_environment_variables = {
      COSMOS_KEY     = azurerm_cosmosdb_account.main.primary_key
      REDIS_PASSWORD = azurerm_redis_cache.main.primary_access_key
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password = azurerm_container_registry.main.admin_password
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [azurerm_container_group.auth_api]
}

# Log Message Processor (Python)
resource "azurerm_container_group" "log_processor" {
  name                = "ci-log-processor-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [azurerm_subnet.app.id]
  
  container {
    name   = "log-processor"
    image  = "${azurerm_container_registry.main.login_server}/log-processor:latest"
    cpu    = "0.25"
    memory = "0.5"

    environment_variables = {
      ENVIRONMENT = var.environment
      REDIS_HOST  = azurerm_redis_cache.main.hostname
      REDIS_PORT  = "6379"
    }

    secure_environment_variables = {
      REDIS_PASSWORD = azurerm_redis_cache.main.primary_access_key
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password = azurerm_container_registry.main.admin_password
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}