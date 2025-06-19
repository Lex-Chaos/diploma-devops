resource "yandex_vpc_security_group" "diploma-kubernetes-sg" {
  name        = "diploma-kubernetes-sg"
  network_id  = yandex_vpc_network.diploma-network.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Kubernetes API"
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "etcd"
    protocol       = "TCP"
    port           = 2379-2380
    v4_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  }

  ingress {
    description    = "Kubelet API"
    protocol       = "TCP"
    port           = 10250
    v4_cidr_blocks = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  }

# Для Grafana
  ingress {
    description    = "Grafana"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Grafana NodePort"
    protocol       = "TCP"
    port           = 30080
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Grafana Health Checks"
    protocol       = "TCP"
    port           = 30080
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

#Для приложения
  ingress {
    description    = "App NodePort"
    protocol       = "TCP"
    port           = 30081
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Full outgoing access"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}