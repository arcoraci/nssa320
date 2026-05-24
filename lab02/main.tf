# =============================================================================
# main.tf - Lab 2: Ubuntu 26.04 Desktop on Hyper-V
# =============================================================================

terraform {
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.2"
    }
  }
}

provider "hyperv" {
  use_ntlm = true
  https    = false
  port     = 5985

  host     = "localhost"
  user     = "student"
  password = "student"
}

# =============================================================================
resource "hyperv_machine_instance" "ubuntu" {
  name       = "ubuntu-26-04"
  generation = 2
  state      = "Off"

  # --------------------- Hardware ---------------------
  memory_startup_bytes = var.memory_size
  processor_count      = 2
  static_memory        = true

  # --------------------- Networking ---------------------
  network_adaptors {
    name        = "lan0"
    switch_name = "Default Switch"
  }

  # --------------------- Storage - Ubuntu ISO ---------------------
  dvd_drives {
    controller_number   = 0
    controller_location = 1
    path                = "C:/isos/ubuntu-26.04-desktop-amd64.iso"
    resource_pool_name  = "Primordial" # Prevents common apply error
  }

  # --------------------- Firmware & Boot Order ---------------------
  vm_firmware {
    enable_secure_boot = "Off"
  }
}