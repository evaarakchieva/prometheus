terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
}

variable "my_token" {
  type = string
}

variable "my_cloud_id" {
  type = string
}

variable "my_folder_id" {
  type = string
}

provider "yandex" {
  token     = var.my_token
  cloud_id  = var.my_cloud_id
  folder_id = var.my_folder_id
  zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "vpc_network" {
  name = "vm-network"
}

resource "yandex_vpc_subnet" "vpc_subnet" {
  name           = "vm-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc_network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_compute_instance" "prometheus-server" {
  name        = "prometheus-server-1"
  zone        = "ru-central1-a"
  hostname    = "prometheus-server"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id    = "fd89ls0nj4oqmlhhi568" # Ubuntu 22.04 image_id
      size        = 20
      type        = "network-ssd"
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.vpc_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/prometheus_server_key.pub")}"
    user-data = file("${path.module}/prometheus_installation_ubuntu.sh")
  }
}

resource "yandex_compute_instance" "prometheus-node-exporter" {
  name        = "prometheus-node-exporter"
  zone        = "ru-central1-a"
  hostname    = "prometheus-node-exporter"
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id    = "fd89ls0nj4oqmlhhi568" # Ubuntu 22.04 image_id
      size        = 20
      type        = "network-ssd"
    }
  }
  
  network_interface {
    subnet_id = yandex_vpc_subnet.vpc_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/node_exporter_key.pub")}"
    user-data = file("${path.module}/prometheus_node_exporter.sh")
  }
}

