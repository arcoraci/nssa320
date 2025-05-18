##############################################
# main.tf – Deploy an Ubuntu VM on Hyper-V
# -------------------------------------------
# This Terraform configuration:
# 1. Pulls in the community Hyper-V provider.
# 2. Connects to the local Hyper-V host via WinRM.
# 3. Defines and powers-off an Ubuntu 24.04 VM
#    with 2 vCPUs, 2 GiB RAM, an attached ISO,
#    and default-switch networking.
##############################################


# ---------- 1. Tell Terraform which provider to use ----------
terraform {
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.2"
    }
  }
}

# ---------- 2. Configure the Hyper-V provider ----------
provider "hyperv" {
  use_ntlm = true
  https    = false
  port     = 5985
  
  # Hostname or IP of the Windows machine running Hyper-V
  host     = "gpavks" 
  
  # Local Windows credentials that have Hyper-V rights
  user     = "student"
  password = "student"
}

# ---------- 3. Declare the virtual machine ----------
resource "hyperv_machine_instance" "ubuntu" {
  name                 = "ubuntu-24-04"
  generation           = 2
  state                = "Off"
  
  # ---------- Hardware ----------
  memory_startup_bytes = 2147483648
  processor_count      = 2
  static_memory        = true

  # ---------- Networking ----------
  network_adaptors {
    name        = "lan0"
    switch_name = "Default Switch"
  }
  
  # ---------- Storage: attach Ubuntu ISO as a virtual DVD ----------
  dvd_drives {
    controller_number   = 0
    controller_location = 1
    path                = "C:/isos/ubuntu-24.04.2-desktop-amd64.iso"
  }

  # ---------- Firmware & boot order ----------
  vm_firmware {
    enable_secure_boot = "On"               

    boot_order {
      boot_type           = "DvdDrive"    
      controller_number   = 0
      controller_location = 1
    }
  }
}
=======
terraform {
  required_version = ">= 1.7"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # When Terraform is executed **inside WSL 2** the default Unix socket works.
  host = "unix:///var/run/docker.sock"

  # If you run Terraform from PowerShell (outside WSL 2) change to:
  # host = "npipe:////./pipe/docker_engine"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "tf-demo-nginx"
  image = docker_image.nginx.latest
  ports {
    internal = 80
    external = 8080
  }
}
=======
# ---------- RESOURCE GROUP ----------
resource "azurerm_resource_group" "rg" {
  name     = "rg-nssa320-${var.student_id}"
  location = "eastus"
}

# ---------- VIRTUAL NETWORK ----------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.student_id}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ---------- NETWORK SECURITY ----------
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-ssh"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ---------- PUBLIC IP + NIC ----------
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.student_id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.student_id}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# ---------- LINUX VM ----------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.student_id}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure_id.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

output "ssh_command" {
  value = "ssh azureuser@${azurerm_public_ip.pip.ip_address}"
}