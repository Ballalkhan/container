# rocky-linux-packer.pkr.hcl

# Required Packer version
packer {
  required_version = ">= 1.7.0"

  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "display" {
  type    = string
  default = "none"
}

variable "output_directory" {
  type    = string
  default = "./output/image-aarch64"
}

# Define the source image builder - for QEMU
source "qemu" "rocky_linux" {
  iso_url       = "https://download.rockylinux.org/pub/rocky/9.5/isos/aarch64/Rocky-9.5-aarch64-minimal.iso"
  iso_checksum  = "sha256:5bd7a6bd90ae54c9f9e4c2e8c957b33fb61fbffcede251fe73f0b0beb42fd9ca"
  qemu_binary   = "qemu-system-aarch64"
  output_directory = var.output_directory
  http_directory = "."
  disk_size     = "40960"
  memory        = "2048"
  cores         = 4
  cpu_model     = "host"
  qemuargs = [
    ["-display", var.display],
    ["-machine", "type=virt,accel=hvf,highmem=off"],
    ["-bios", "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"],
    [ "-device", "ramfb" ],
    [ "-device", "qemu-xhci" ],
    [ "-device", "usb-kbd" ],
    [ "-boot", "d" ],
  ]
  ssh_port =  22
  ssh_password = "rocky"
  ssh_username = "root"
  ssh_timeout = "30m"
  headless      = false
  ssh_wait_timeout = "30m"
  shutdown_command = "/sbin/halt -h -p"
  boot_wait = "7s"
  boot_command = [
    "e",              # Press 'e' to edit the default boot entry
    "<down><down>",   # Navigate down to the kernel line (adjust the number of <down> presses as needed)
    "<end>",          # Move to the end of the line
    " inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/http/ks.cfg",  # Append the installation parameters
    "<f10>"        # Boot with the modified parameters
  ]
}

# Provision with an external shell script
build {
  sources = ["source.qemu.rocky_linux"]

  provisioner "shell" {
    script = "install.sh" 
  }
  
  provisioner "shell" {
    script = "preset.sh"
  }
}
