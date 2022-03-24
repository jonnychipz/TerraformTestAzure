terraform {
  backend "azurerm" {
    resource_group_name  = "mks-infra"
    storage_account_name = "mkststate"
    container_name       = "tstate"
    key                  = "jht8B87DK6N3w2oTdBxpIa8jWa0DkaxHnkgAY5hgcsWRs7xglq/iJ+yMTPAhlROgc4vR9ha0uDmsngCYSRQFlg=="
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
# Create our Resource Group - mks-RG
resource "azurerm_resource_group" "rg" {
  name     = "mks-app01"
  location = "UK South"
}
# Create our Virtual Network - mks-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "mksvnet"
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
# Create our Azure Storage Account - mkssa
resource "azurerm_storage_account" "mkssa" {
  name                     = "mkssa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "mksenv1"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "mksvm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - mks-VM01
resource "azurerm_virtual_machine" "mksvm01" {
  name                  = "mksvm01"
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
    name              = "mksvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_data_disk {
     name              = "datadisk_new_${count.index}"
     managed_disk_type = "Standard_LRS"
     create_option     = "Empty"
     lun               = 0
     disk_size_gb      = "1023"
   }
  os_profile {
    computer_name  = "mksvm01"
    admin_username = "mks"
    admin_password = "Password123$"
  }
  os_profile_windows_config {
  }
}
