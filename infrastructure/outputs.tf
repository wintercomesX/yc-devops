output "cluster_id" {
  value = yandex_kubernetes_cluster.main.id
}

output "cluster_name" {
  value = yandex_kubernetes_cluster.main.name
}

output "container_registry_id" {
  value = yandex_container_registry.main.id
}

output "subnet_a_id" {
  value = yandex_vpc_subnet.subnet_a.id
}

output "network_id" {
  value = yandex_vpc_network.main.id
}
