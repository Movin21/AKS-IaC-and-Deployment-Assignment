variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-assignment-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "my-aks-cluster"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2_v2"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "myaks"
}

variable "storage_account_prefix" {
  description = "Prefix for the storage account name (will be randomized)"
  type        = string
  default     = "aksstate"
}

variable "container_name" {
  description = "Name of the Blob container for Terraform state"
  type        = string
  default     = "tfstate"
}