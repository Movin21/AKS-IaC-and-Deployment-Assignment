# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "aks-assignment-rg"
  location = "East US"
}

# Creating the AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myaks"

  default_node_pool {
    name       = "default"
    node_count = 2  
    vm_size    = "Standard_D2_v2"  
  }

  identity {
    type = "SystemAssigned"  
  }

  network_profile {
    network_plugin = "kubenet"  
  }
}


output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}