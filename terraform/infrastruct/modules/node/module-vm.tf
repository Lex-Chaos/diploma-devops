variable "name" {}
variable "hostname" {}
variable "zone" {}
variable "subnet" {}
variable "cpu" {}
variable "ram" {}
variable "disk-size" {}
variable "platform" {}
variable "image-family" {}
variable "sec-group-id" {}
variable "user-data" {}
variable "ssh-key" {}

data "yandex_compute_image" "ubuntu" {
  family = var.image-family #"ubuntu-2004-lts"
}

resource "yandex_compute_instance" "vm" {
  name        = "${var.name}"
  hostname    = "${var.hostname}"
  platform_id = "${var.platform}"
  zone        = var.zone

  resources {
    cores  = var.cpu
    memory = var.ram
  }

  boot_disk {
    initialize_params {
        image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.disk-size
    }
  }

  network_interface {
    subnet_id          = var.subnet
    nat                = true
    security_group_ids = var.sec-group-id
  }

    metadata = {
    user-data = templatefile(var.user-data, {
      ssh_key = var.ssh-key
    })
    serial-port-enable = 1
  }
}

output "external-instance-ip" {
  value = yandex_compute_instance.vm.network_interface.0.nat_ip_address
}

output "internal-instance-ip" {
  value = yandex_compute_instance.vm.network_interface.0.ip_address
}

output "name" {
  value = yandex_compute_instance.vm.name
}

output "subnet" {
  value = yandex_compute_instance.vm.network_interface[0].subnet_id
}