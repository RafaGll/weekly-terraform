resource "azurerm_virtual_network" "weekly_rafa" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "weekly_rafa" {
  name                  = var.subnet_name
  resource_group_name   = var.resource_group_name
  virtual_network_name  = azurerm_virtual_network.weekly_rafa.name
  address_prefixes      = ["10.0.1.0/24"]
}

# Crear el balanceador de carga interno
resource "azurerm_lb" "weekly_rafa" {
  name                = var.lb_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku = var.sku_type

  frontend_ip_configuration {
    name                          = "frontend-ip"
    subnet_id                     = azurerm_subnet.weekly_rafa.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Crear el grupo de direcciones de backend
resource "azurerm_lb_backend_address_pool" "weekly_rafa" {
  loadbalancer_id = azurerm_lb.weekly_rafa.id
  name            = var.lb_backend_pool_name
}

# Crear las interfaces de red y las máquinas virtuales
resource "azurerm_network_interface" "weekly_rafa" {
  for_each            = var.vms
  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${each.key}-ip-config"
    subnet_id                     = azurerm_subnet.weekly_rafa.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "weekly_rafa" {
  for_each              = var.vms
  name                  = each.value.name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = each.value.size
  disable_password_authentication = false
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.weekly_rafa[each.key].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

# Asociar las interfaces de red al grupo de direcciones de backend
resource "azurerm_lb_backend_address_pool_address" "weekly_rafa" {
  for_each = var.vms
  name     = "${each.key}-backend-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.weekly_rafa.id
  virtual_network_id      = azurerm_virtual_network.weekly_rafa.id
  ip_address             = azurerm_network_interface.weekly_rafa[each.key].private_ip_address
}

import {
  to = azurerm_virtual_network.weekly_rafa
  id = "/subscriptions/86f76907-b9d5-46fa-a39d-aff8432a1868/resourceGroups/rg-rgonzalez-dvfinlab/providers/Microsoft.Network/virtualNetworks/vm_vnet"
}