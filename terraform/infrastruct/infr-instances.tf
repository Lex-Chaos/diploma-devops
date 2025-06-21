variable "master-count" {
  description = "Number of master nodes"
  default     = 1
}

variable "worker-count" {
  description = "Number of worker nodes"
  default     = 2
}

variable "zones" {
  description = "Yandex Cloud availability zones"
  default     = [
    "ru-central1-a",
    "ru-central1-b",
    "ru-central1-d"
    ]
}

locals {
  subnets = {
    "ru-central1-a" = yandex_vpc_subnet.diploma-subnet-a.id
    "ru-central1-b" = yandex_vpc_subnet.diploma-subnet-b.id
    "ru-central1-d" = yandex_vpc_subnet.diploma-subnet-d.id
  }
}

# Модуль для создания мастер-нод
module "masters" {
  source        = "./modules/node"
  image-family  = "ubuntu-2404-lts"
  platform      = "standard-v3"
  count         = var.master-count
  name          = "master-${count.index+1}"
  hostname      = "master-${count.index+1}"
  zone          = element(var.zones, count.index % length(var.zones))
  subnet        = local.subnets[element(var.zones, count.index % length(var.zones))]
  cpu           = 2
  ram           = 4
  disk-size     = 10
  sec-group-id  = [yandex_vpc_security_group.diploma-kubernetes-sg.id]
  user-data     = "./templates/cloud-init.yml"
  ssh-key       = var.ssh_public_key
}

# # Модуль для создания воркер-нод
module "workers" {
  source        = "./modules/node"
  image-family  = "ubuntu-2404-lts"
  platform      = "standard-v3"
  count         = var.worker-count
  name          = "worker-${count.index+1}"
  hostname      = "worker-${count.index+1}"
  zone          = element(var.zones, count.index % length(var.zones))
  subnet        = local.subnets[element(var.zones, count.index % length(var.zones))]
  cpu           = 2
  ram           = 4
  disk-size     = 10
  sec-group-id  = [yandex_vpc_security_group.diploma-kubernetes-sg.id]
  user-data     = "./templates/cloud-init.yml"
  ssh-key       = var.ssh_public_key
}

# Генерация динамического inventory
resource "local_file" "ansible_inventory" {
  filename = var.github-actions == "true" ? "/tmp/diploma-inventory/inventory" : "../../ansible/inventory"
  content  = templatefile("templates/inventory.tftpl", {
    masters = [for m in module.masters : {
      name = m.name,
      ip   = m.external-instance-ip
    }]
    workers = [for w in module.workers : {
      name = w.name,
      ip   = w.external-instance-ip
    }]
    
    load_balancer_ip = one(one(yandex_lb_network_load_balancer.k8s-lb.listener[*]).external_address_spec[*]).address
  })
}

#