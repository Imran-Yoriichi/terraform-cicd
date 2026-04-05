terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name     = "aks-grp"
  
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aks-dns"
  kubernetes_version  = "1.33.7"

  # Default node pool — system nodes
  default_node_pool {
    name                = "systempool"
    node_count          = 1
    vm_size             = "standard_dc2s_v3"
    os_disk_size_gb     = 50
    type                = "VirtualMachineScaleSets"

    # Enable autoscaling
    
    min_count           = null
    max_count           = null

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "dev"
    }
  }

  # Use system-assigned managed identity (no service principal needed)
  identity {
    type = "SystemAssigned"
  }

  # Network profile
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  # Enable RBAC
  role_based_access_control_enabled = true

  # Azure Monitor for containers
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  }

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Optional user node pool — for your app workloads

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "law-aks-demo"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
 

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
