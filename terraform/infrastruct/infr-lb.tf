resource "yandex_lb_network_load_balancer" "k8s-lb" {
  name = "k8s-lb"

  listener {
    name = "k8s-listener"
    port = 6443
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-masters.id

    healthcheck {
      name = "tcp-healthcheck"
      tcp_options {
        port = 6443
      }
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      healthy_threshold   = 2
    }
  }
}

resource "yandex_lb_target_group" "k8s-masters" {
  name      = "k8s-masters"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = module.masters
    content {
      subnet_id = target.value.subnet
      address   = target.value.internal-instance-ip
    }
  }
}

output "load_balancer_ip" {
  value = yandex_lb_network_load_balancer.k8s-lb.listener[*].external_address_spec[*].address
}