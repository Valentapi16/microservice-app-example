variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "microservice-app"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central US"  # Región más compatible con cuentas estudiantiles
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-microservice-app-dev"
}

variable "allowed_ips" {
  description = "IP addresses allowed to access resources"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Cambiar en producción
}