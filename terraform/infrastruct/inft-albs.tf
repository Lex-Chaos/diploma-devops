# alb для grafana
resource "yandex_alb_load_balancer" "grafana_alb" {
  name        = "grafana-alb"
  network_id  = yandex_vpc_network.diploma-network.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.diploma-subnet-a.id
    }
  }

  listener {
    name = "grafana-http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.grafana_router.id
      }
    }
  }
}

resource "yandex_alb_http_router" "grafana_router" {
  name = "grafana-router"
}

resource "yandex_alb_virtual_host" "grafana_vhost" {
  name           = "grafana-virtual-host"
  http_router_id = yandex_alb_http_router.grafana_router.id
  authority      = ["*"]

  route {
    name = "grafana-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.grafana_backend.id
        timeout          = "3s"
      }
    }
  }
}

resource "yandex_alb_backend_group" "grafana_backend" {
  name = "grafana-backend-group"

  http_backend {
    name             = "grafana-http-backend"
    weight           = 1
    port             = 30080
    target_group_ids = [yandex_alb_target_group.grafana_targets.id]
    
    healthcheck {
      timeout          = "1s"
      interval         = "2s"
      healthcheck_port = 30080
      http_healthcheck {
        path = "/api/health"
      }
    }
    
    load_balancing_config {
      panic_threshold = 50
    }
  }
}

resource "yandex_alb_target_group" "grafana_targets" {
  name = "grafana-targets"

  dynamic "target" {
    for_each = concat(module.masters, module.workers)
    content {
      ip_address   = target.value.internal-instance-ip
      subnet_id    = target.value.subnet
    }
  }
}

# Адрес grafana вот такой
output "grafana_alb_ip" {
  value = "grafana-address - http:\\${yandex_alb_load_balancer.grafana_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
}

# alb для приложения
resource "yandex_alb_load_balancer" "app_alb" {
  name        = "app-alb"
  network_id  = yandex_vpc_network.diploma-network.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.diploma-subnet-a.id
    }
  }

  listener {
    name = "app-http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.app_router.id
      }
    }
  }
}

resource "yandex_alb_http_router" "app_router" {
  name = "app-router"
}

resource "yandex_alb_virtual_host" "app_vhost" {
  name           = "app-virtual-host"
  http_router_id = yandex_alb_http_router.app_router.id
  authority      = ["*"]

  route {
    name = "app-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.app_backend.id
        timeout          = "3s"
      }
    }
  }
}

resource "yandex_alb_backend_group" "app_backend" {
  name = "app-backend-group"

  http_backend {
    name             = "app-http-backend"
    weight           = 1
    port             = 30081
    target_group_ids = [yandex_alb_target_group.app_targets.id]
    
    healthcheck {
      timeout          = "1s"
      interval         = "2s"
      healthcheck_port = 30081
      http_healthcheck {
        path = "/"
      }
    }
    
    load_balancing_config {
      panic_threshold = 50
    }
  }
}

resource "yandex_alb_target_group" "app_targets" {
  name = "app-targets"

  dynamic "target" {
    for_each = module.workers
    content {
      ip_address   = target.value.internal-instance-ip
      subnet_id    = target.value.subnet
    }
  }
}

# Адрес приложения
output "app_alb_ip" {
  value = "app-address - http:\\${yandex_alb_load_balancer.app_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
}