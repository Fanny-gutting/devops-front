provider "azurerm" {
  version = "~> 2.5"
  features {}
}

resource "azurerm_resource_group" "packer" {
  name = "packer"
  location = "West Europe"
}

resource "azurerm_virtual_network" "packer_network" {
  name = "packer-network"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.packer.location
  resource_group_name = azurerm_resource_group.packer.name
}

resource "azurerm_subnet" "packer_subnet" {
  name = "packer-subnet"
  resource_group_name = azurerm_resource_group.packer.name
  virtual_network_name = azurerm_virtual_network.packer_network.name
  address_prefix = "10.0.2.0/24"
}


resource "azurerm_network_interface" "nginx_nic" {
  name = "nginx-nic"
  location = azurerm_resource_group.packer.location
  resource_group_name = azurerm_resource_group.packer.name

  ip_configuration {
  name = "nginx-ip-config"
  subnet_id = azurerm_subnet.packer_subnet.id
  private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "nginx_vm" {
  name = "nginx-vm"
  location = azurerm_resource_group.packer.location
  resource_group_name = azurerm_resource_group.packer.name
  network_interface_ids = [azurerm_network_interface.nginx_nic.id]
  vm_size = "Standard_B1s"

  storage_image_reference {
  id = azurerm_image.nginx_image.id
  }

  storage_os_disk {
  name = "nginx-os-disk"
  caching = "ReadWrite"
  create_option = "FromImage"
  managed_disk_type = "Standard_LRS"
  }

  os_profile {
  computer_name = "nginx-vm"
  admin_username = "azureuser"
  admin_password = "{{user admin_password}}"
  }

  os_profile_linux_config {
  disable_password_authentication = false
  }
}

output "nginx_ip_address" {
  value = azurerm_network_interface.nginx_nic.private_ip_address
}