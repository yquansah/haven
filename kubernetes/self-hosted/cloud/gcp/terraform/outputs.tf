output "control_plane_external_ip" {
  description = "External IP address of the control plane node"
  value       = google_compute_instance.yke_control_plane.network_interface[0].access_config[0].nat_ip
}

output "control_plane_internal_ip" {
  description = "Internal IP address of the control plane node"
  value       = google_compute_instance.yke_control_plane.network_interface[0].network_ip
}

output "worker_node_external_ips" {
  description = "External IP addresses of the worker nodes"
  value       = [for instance in google_compute_instance.yke_worker_node : instance.network_interface[0].access_config[0].nat_ip]
}

output "worker_node_internal_ips" {
  description = "Internal IP addresses of the worker nodes"
  value       = [for instance in google_compute_instance.yke_worker_node : instance.network_interface[0].network_ip]
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.yke_vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.yke_public_subnet.name
}

output "control_plane_load_balancer_ip" {
  description = "External IP address of the control plane load balancer"
  value       = google_compute_forwarding_rule.yke_control_plane_forwarding_rule.ip_address
}

output "traefik_load_balancer_ip" {
  description = "External IP address of the Traefik ingress load balancer"
  value       = google_compute_forwarding_rule.yke_traefik_forwarding_rule.ip_address
}

output "ansible_inventory" {
  description = "Ansible inventory configuration"
  value = templatefile("${path.module}/templates/inventory.ini.tpl", {
    control_plane_ip = google_compute_instance.yke_control_plane.network_interface[0].access_config[0].nat_ip
    worker_ips       = [for instance in google_compute_instance.yke_worker_node : instance.network_interface[0].access_config[0].nat_ip]
    ssh_user         = var.gce_ssh_user
  })
}