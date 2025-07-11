# Worker Node Firewall Rules
resource "google_compute_firewall" "yke_worker_node_bgp_control_plane" {
  name    = "yke-worker-node-bgp-control-plane"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["179"]
  }

  source_tags = ["yke-control-plane"]
  target_tags = ["yke-worker-node"]
}

resource "google_compute_firewall" "yke_worker_node_bgp_worker" {
  name    = "yke-worker-node-bgp-worker"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["179"]
  }

  source_tags = ["yke-worker-node"]
  target_tags = ["yke-worker-node"]
}

resource "google_compute_firewall" "yke_worker_node_ip_encapsulation_control_plane" {
  name    = "yke-worker-node-ip-encapsulation-control-plane"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "4"
  }

  source_tags = ["yke-control-plane"]
  target_tags = ["yke-worker-node"]
}

resource "google_compute_firewall" "yke_worker_node_ip_encapsulation_worker" {
  name    = "yke-worker-node-ip-encapsulation-worker"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "4"
  }

  source_tags = ["yke-worker-node"]
  target_tags = ["yke-worker-node"]
}

resource "google_compute_firewall" "yke_worker_node_ssh" {
  name    = "yke-worker-node-ssh"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["yke-worker-node"]
}

resource "google_compute_firewall" "yke_worker_node_kubelet" {
  name    = "yke-worker-node-kubelet"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10250"]
  }

  source_ranges = [var.vpc_cidr_range]
  target_tags   = ["yke-worker-node"]
}

resource "google_compute_firewall" "yke_worker_node_kube_proxy" {
  name    = "yke-worker-node-kube-proxy"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10256"]
  }

  source_ranges = [var.vpc_cidr_range]
  target_tags   = ["yke-worker-node"]
}

# Control Plane Firewall Rules
resource "google_compute_firewall" "yke_control_plane_bgp_worker" {
  name    = "yke-control-plane-bgp-worker"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["179"]
  }

  source_tags = ["yke-worker-node"]
  target_tags = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_bgp_control_plane" {
  name    = "yke-control-plane-bgp-control-plane"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["179"]
  }

  source_tags = ["yke-control-plane"]
  target_tags = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_ip_encapsulation_worker" {
  name    = "yke-control-plane-ip-encapsulation-worker"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "4"
  }

  source_tags = ["yke-worker-node"]
  target_tags = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_ip_encapsulation_control_plane" {
  name    = "yke-control-plane-ip-encapsulation-control-plane"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "4"
  }

  source_tags = ["yke-control-plane"]
  target_tags = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_ssh" {
  name    = "yke-control-plane-ssh"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_kube_api_server_vpc" {
  name    = "yke-control-plane-kube-api-server-vpc"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = [var.vpc_cidr_range]
  target_tags   = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_kube_api_server_external" {
  name    = "yke-control-plane-kube-api-server-external"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_needed_ports" {
  name    = "yke-control-plane-needed-ports"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["10248-10260"]
  }

  source_ranges = [var.vpc_cidr_range]
  target_tags   = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_etcd" {
  name    = "yke-control-plane-etcd"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["2379-2380"]
  }

  source_ranges = [var.vpc_cidr_range]
  target_tags   = ["yke-control-plane"]
}

resource "google_compute_firewall" "yke_control_plane_port_80_hack" {
  name    = "yke-control-plane-port-80-hack"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["yke-load-balancer"]
  target_tags = ["yke-control-plane"]
}