resource "yandex_vpc_network" "k8s_net" {
  name = "K8s-Net"
}

resource "yandex_vpc_subnet" "k8s-4-subnet" {
  name           = "K8s4Subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.k8s_net.id}"
  v4_cidr_blocks = ["10.12.4.0/24"]
}

resource "yandex_compute_instance" "cp1" {
  name = "k8s-cp1"
  folder_id = "b1g3nhsgfgnbjbrfnlri"

  resources {
    cores  = 2
    core_fraction = 100
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd81hgrcv6lsnkremf32"
      size = 5
      type = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.k8s-4-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "anything:${file("~/.ssh/id_rsa.pub")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

resource "yandex_compute_instance" "k8s-node1" {
  name = "k8s-node1"
  folder_id = "b1g3nhsgfgnbjbrfnlri"

  resources {
    cores  = 2
    core_fraction = 100
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd81hgrcv6lsnkremf32"
      size = 5
      type = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.k8s-4-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "zubarev_va:${file("~/.ssh/id_rsa.pub")}"
  }

  scheduling_policy {
    preemptible = true
  }
}
