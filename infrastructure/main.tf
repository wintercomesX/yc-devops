# VPC and Subnets - Using zones A, B, and D (C is DOWN)
resource "yandex_vpc_network" "main" {
  name = "main-network"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.1.1.0/24"]
}

resource "yandex_vpc_subnet" "subnet_b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.1.2.0/24"]
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.1.4.0/24"]
}

# Service Accounts for K8s
resource "yandex_iam_service_account" "k8s_cluster" {
  name        = "k8s-cluster-sa"
  description = "Service account for Kubernetes cluster"
}

resource "yandex_iam_service_account" "k8s_nodes" {
  name        = "k8s-nodes-sa"
  description = "Service account for Kubernetes nodes"
}

# FIXED: Correct IAM bindings with proper roles
resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_vpc_user" {
  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_load_balancer_admin" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster.id}"
}

# ADDED: Additional required permission for cluster creation
resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster.id}"
}

# Node group service account permissions
resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_agent" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_compute_viewer" {
  folder_id = var.folder_id
  role      = "compute.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

# ADDED: Required for node operations
resource "yandex_resourcemanager_folder_iam_member" "k8s_nodes_vpc_user" {
  folder_id = var.folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}"
}

# Security Group - Improved with all required ports
resource "yandex_vpc_security_group" "k8s_main" {
  name       = "k8s-main-sg"
  network_id = yandex_vpc_network.main.id

  # API server access
  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS for applications
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS for applications
  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all internal cluster communication
  ingress {
    protocol       = "TCP"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["10.1.0.0/16"]
  }

  ingress {
    protocol       = "UDP"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["10.1.0.0/16"]
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.1.0.0/16"]
  }

  # Allow all outbound traffic
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Kubernetes Cluster (Managed)
resource "yandex_kubernetes_cluster" "main" {
  name       = "main-k8s-cluster"
  network_id = yandex_vpc_network.main.id

  master {
#    version = "1.27"
    zonal {
      zone      = yandex_vpc_subnet.subnet_a.zone
      subnet_id = yandex_vpc_subnet.subnet_a.id
    }

    public_ip = true

    security_group_ids = [yandex_vpc_security_group.k8s_main.id]

    maintenance_policy {
      auto_upgrade = false
      maintenance_window {
        start_time = "15:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.k8s_cluster.id
  node_service_account_id = yandex_iam_service_account.k8s_nodes.id

  # FIXED: Include all required dependencies
  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_cluster_agent,
    yandex_resourcemanager_folder_iam_member.k8s_cluster_vpc_user,
    yandex_resourcemanager_folder_iam_member.k8s_cluster_load_balancer_admin,
    yandex_resourcemanager_folder_iam_member.k8s_cluster_editor,
    yandex_resourcemanager_folder_iam_member.k8s_nodes_agent,
    yandex_resourcemanager_folder_iam_member.k8s_nodes_compute_viewer,
    yandex_resourcemanager_folder_iam_member.k8s_nodes_vpc_user,
  ]
}

# Kubernetes Node Group
resource "yandex_kubernetes_node_group" "main_nodes" {
  cluster_id = yandex_kubernetes_cluster.main.id
  name       = "main-node-group"
#  version    = "1.27"

  instance_template {
    platform_id = "standard-v2"
    
    resources {
      memory = 4
      cores  = 2
      core_fraction = 20
    }

    boot_disk {
      type = "network-hdd"
      size = 30
    }

    scheduling_policy {
      preemptible = true
    }

    network_interface {
      nat        = true
      subnet_ids = [
        yandex_vpc_subnet.subnet_a.id,
        yandex_vpc_subnet.subnet_b.id,
        yandex_vpc_subnet.subnet_d.id
      ]
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    location {
      zone = "ru-central1-b"
    }
    location {
      zone = "ru-central1-d"
    }
  }

  maintenance_policy {
    auto_upgrade = false
    auto_repair  = true
    maintenance_window {
      start_time = "15:00"
      duration   = "3h"
    }
  }
}

# Container Registry
resource "yandex_container_registry" "main" {
  name = "main-registry"
}

resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = yandex_container_registry.main.id
  role        = "container-registry.images.puller"
  members = [
    "serviceAccount:${yandex_iam_service_account.k8s_nodes.id}",
  ]
}

