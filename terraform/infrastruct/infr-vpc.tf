resource "yandex_vpc_network" "diploma-network" {
  name = "diploma-network"
}

resource "yandex_vpc_subnet" "diploma-subnet-a" {
  name           = "diploma-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diploma-network.id
  v4_cidr_blocks = ["10.1.0.0/16"]
}

resource "yandex_vpc_subnet" "diploma-subnet-b" {
  name           = "diploma-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diploma-network.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}

resource "yandex_vpc_subnet" "diploma-subnet-d" {
  name           = "diploma-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.diploma-network.id
  v4_cidr_blocks = ["10.3.0.0/16"]
}