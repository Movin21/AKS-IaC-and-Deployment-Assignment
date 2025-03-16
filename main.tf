# Random string for unique storage account name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    project     = "aks-assignment"
    environment = "dev"
  }
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "state" {
  name                     = "${var.storage_account_prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    project     = "aks-assignment"
    environment = "dev"
  }
}

# Blob Container for Terraform State
resource "azurerm_storage_container" "state_container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"  # Grants Contributor role to the cluster
  }

  network_profile {
    network_plugin = "kubenet"
  }

  tags = {
    project     = "aks-assignment"
    environment = "dev"
  }
}

# Outputs
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.state.name
}

output "external_ip_command" {
  value       = "kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
  description = "Run this command to get the nginx service external IP."
}