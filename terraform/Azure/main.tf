terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "hpc_resource_group" {
  name     = "hpc-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "hpc_virtual_network" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hpc_resource_group.location
  resource_group_name = azurerm_resource_group.hpc_resource_group.name
}

resource "azurerm_subnet" "hpc_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.hpc_resource_group.name
  virtual_network_name = azurerm_virtual_network.hpc_virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "hpc_public_ip" {
  name                = "hpc-public-ip-${count.index}"
  count               = 4
  location            = azurerm_resource_group.hpc_resource_group.location
  resource_group_name = azurerm_resource_group.hpc_resource_group.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "hpc_network_interface" {
  name                = "hpc-network-interface-${count.index}"
  count               = 4
  location            = azurerm_resource_group.hpc_resource_group.location
  resource_group_name = azurerm_resource_group.hpc_resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hpc_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hpc_public_ip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "hpc_machine" {
  name                = "hpc-machine-${count.index}"
  count               = 4
  resource_group_name = azurerm_resource_group.hpc_resource_group.name
  location            = azurerm_resource_group.hpc_resource_group.location
  size                = "Standard_DS11-1_v2"
  admin_username      = "hpc"
  network_interface_ids = [
    azurerm_network_interface.hpc_network_interface[count.index].id,
  ]

  admin_ssh_key {
    username   = "hpc"
    public_key = file("../hpc.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}