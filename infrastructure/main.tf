# ====================================================
# Infraestructura Moderna en Azure para Microservicios
# Usando Container Apps (no Container Groups)
# ====================================================

# Random suffix para nombres únicos
resource "random_id" "suffix" {
  byte_length = 4
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Redis Cache (para Cache Aside Pattern)
resource "azurerm_redis_cache" "main" {
  name                 = "redis-${var.project_name}-${var.environment}-${random_id.suffix.hex}"
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

# Log Analytics Workspace (requerido para Container Apps)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Container App Environment (plataforma moderna para contenedores)
resource "azurerm_container_app_environment" "main" {
  name                     = "cae-${var.project_name}-${var.environment}"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ====================================================
# CONTAINER APPS (modernos, no Container Groups)
# ====================================================

# Frontend Container App

resource "azurerm_container_app" "frontend" {
  name                         = "ca-frontend-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.main.login_server
    username            = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  template {
    container {
      name   = "frontend"
      image  = "${azurerm_container_registry.main.login_server}/frontend:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      # URLs FIJAS (sin revision-specific paths)
      env {
        name  = "USERS_API_URL"
        value = "https://ca-users-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io"
      }
      env {
        name  = "AUTH_API_URL"
        value = "https://ca-auth-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io"
      }
      env {
        name  = "TODOS_API_URL"
        value = "https://ca-todos-api-dev.livelywater-96a1966e.westus2.azurecontainerapps.io"
      }

      env {
        name  = "NGINX_DEBUG"
        value = "1"
      }
    }

    min_replicas = 1  # CAMBIAR DE 0 A 1 para evitar cold starts
    max_replicas = 10
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 80
    
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [
    azurerm_container_app.users_api,
    azurerm_container_app.auth_api,
    azurerm_container_app.todos_api
  ]
}

# Users API Container App
resource "azurerm_container_app" "users_api" {
  name                         = "ca-users-api-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.main.login_server
    username            = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  template {
    container {
      name   = "users-api"
      image  = "${azurerm_container_registry.main.login_server}/users-api:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.enable_cosmosdb ? "cosmos" : "dev"
      }
      env {
        name  = "JWT_SECRET"
        value = "myfancysecretthatislongenoughfor256bits12345678"
      }

      # CosmosDB env vars (condicionales)
      dynamic "env" {
        for_each = var.enable_cosmosdb ? [1] : []
        content {
          name  = "COSMOS_ENDPOINT"
          value = azurerm_cosmosdb_account.main[0].endpoint
        }
      }

      dynamic "env" {
        for_each = var.enable_cosmosdb ? [1] : []
        content {
          name        = "COSMOS_KEY"
          secret_name = "cosmos-key"
        }
      }
    }

    min_replicas = 1
    max_replicas = 5
  }

  # CosmosDB secrets (condicionales)
  dynamic "secret" {
    for_each = var.enable_cosmosdb ? [1] : []
    content {
      name  = "cosmos-key"
      value = azurerm_cosmosdb_account.main[0].primary_key
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 8080
    
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Auth API Container App
resource "azurerm_container_app" "auth_api" {
  name                         = "ca-auth-api-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.main.login_server
    username            = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  secret {
    name  = "redis-password"
    value = azurerm_redis_cache.main.primary_access_key
  }

  template {
    container {
      name   = "auth-api"
      image  = "${azurerm_container_registry.main.login_server}/auth-api:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.main.hostname
      }
      env {
        name  = "REDIS_PORT"
        value = "6380"  # SSL port
      }
      env {
        name  = "USERS_API_URL"
        value = "https://${azurerm_container_app.users_api.latest_revision_fqdn}"
      }
      env {
        name        = "REDIS_PASSWORD"
        secret_name = "redis-password"
      }
      env {
        name  = "JWT_SECRET"
        value = "myfancysecretthatislongenoughfor256bits12345678"
      }
    }

    min_replicas = 1
    max_replicas = 8
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 8080
    
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [azurerm_container_app.users_api]
}

# Todos API Container App (con Cache Aside + Circuit Breaker)
resource "azurerm_container_app" "todos_api" {
  name                         = "ca-todos-api-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.main.login_server
    username            = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  secret {
    name  = "redis-password"
    value = azurerm_redis_cache.main.primary_access_key
  }

  # CosmosDB secrets (condicionales)
  dynamic "secret" {
    for_each = var.enable_cosmosdb ? [1] : []
    content {
      name  = "cosmos-key"
      value = azurerm_cosmosdb_account.main[0].primary_key
    }
  }

  template {
    container {
      name   = "todos-api"
      image  = "${azurerm_container_registry.main.login_server}/todos-api:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "NODE_ENV"
        value = var.environment
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.main.hostname
      }
      env {
        name  = "REDIS_PORT"
        value = "6380"  # SSL port
      }
      env {
        name  = "AUTH_API_URL"
        value = "https://${azurerm_container_app.auth_api.latest_revision_fqdn}"
      }
      env {
        name        = "REDIS_PASSWORD"
        secret_name = "redis-password"
      }
      env {
        name  = "JWT_SECRET"
        value = "myfancysecretthatislongenoughfor256bits12345678"
      }

      # CosmosDB env vars (condicionales)
      dynamic "env" {
        for_each = var.enable_cosmosdb ? [1] : []
        content {
          name  = "COSMOS_ENDPOINT"
          value = azurerm_cosmosdb_account.main[0].endpoint
        }
      }

      dynamic "env" {
        for_each = var.enable_cosmosdb ? [1] : []
        content {
          name        = "COSMOS_KEY"
          secret_name = "cosmos-key"
        }
      }

      dynamic "env" {
        for_each = var.enable_cosmosdb ? [1] : []
        content {
          name  = "COSMOS_DATABASE"
          value = azurerm_cosmosdb_sql_database.main[0].name
        }
      }
    }

    min_replicas = 1
    max_replicas = 10
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 8080
    
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [azurerm_container_app.auth_api]
}

# Log Processor Container App
resource "azurerm_container_app" "log_processor" {
  name                         = "ca-log-processor-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.main.login_server
    username            = azurerm_container_registry.main.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.main.admin_password
  }

  secret {
    name  = "redis-password"
    value = azurerm_redis_cache.main.primary_access_key
  }

  template {
    container {
      name   = "log-processor"
      image  = "${azurerm_container_registry.main.login_server}/log-message-processor:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.main.hostname
      }
      env {
        name  = "REDIS_PORT"
        value = "6380"  # SSL port
      }
      env {
        name        = "REDIS_PASSWORD"
        secret_name = "redis-password"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 8080
    
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ====================================================
# RECURSOS OPCIONALES (CosmosDB y Application Insights)
# ====================================================

# CosmosDB (opcional) - solo si enable_cosmosdb = true
resource "azurerm_cosmosdb_account" "main" {
  count                     = var.enable_cosmosdb ? 1 : 0
  name                      = "cosmos-${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  
  automatic_failover_enabled = false
  multiple_write_locations_enabled = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  backup {
    type                = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 8
    storage_redundancy  = "Geo"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  count               = var.enable_cosmosdb ? 1 : 0
  name                = "todos-database"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main[0].name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "todos" {
  count                 = var.enable_cosmosdb ? 1 : 0
  name                  = "todos"
  resource_group_name   = azurerm_resource_group.main.name
  account_name          = azurerm_cosmosdb_account.main[0].name
  database_name         = azurerm_cosmosdb_sql_database.main[0].name
  partition_key_path    = "/userId"
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Application Insights (opcional)
resource "azurerm_application_insights" "main" {
  count               = var.enable_application_insights ? 1 : 0
  name                = "appi-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  retention_in_days   = 90

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}