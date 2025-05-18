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
