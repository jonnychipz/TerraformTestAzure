terraform {
  backend "azurerm" {
    resource_group_name  = "abdul-infra"
    storage_account_name = "abdulstorageaccount"
    container_name       = "tstate"
    key                  = "sXOxQO3pvLLLw+Yq8vHcw1zB/1uAUNBInJlIL06pj7CaSLJzoz5ut+g4FZLOaxjWU0JS8/GNwIt0KrL5KTEZxw=="
  }

  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source  = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - abdul-RG
resource "azurerm_resource_group" "ab" {
  name     = "abdul-app01"
  location = "Central US"
}
# Create our Virtual Network - abdul-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "abdulvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - abdulstorageaccount
resource "azurerm_storage_account" "abdulstorageaccount" {
  name                     = "abdulstorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "abdulenv1"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "abdul01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - abdul-VM01
resource "azurerm_virtual_machine" "abdul01" {
  name                  = "abdul01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "abdul01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "abdul01"
    admin_username = "abdul"
    admin_password = "Password123$"
  }
  os_profile_windows_config {
  }
}
