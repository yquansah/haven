# Control plane load balancer
resource "google_compute_http_health_check" "yke_control_plane_health_check" {
  name = "yke-control-plane-health-check"
  
  port                = 80
  request_path        = "/"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_compute_target_pool" "yke_control_plane_target_pool" {
  name = "yke-control-plane-target-pool"
  
  instances = [
    google_compute_instance.yke_control_plane.self_link
  ]
  
  health_checks = [
    google_compute_http_health_check.yke_control_plane_health_check.name
  ]
}

resource "google_compute_forwarding_rule" "yke_control_plane_forwarding_rule" {
  name                  = "yke-control-plane-forwarding-rule"
  port_range            = "6443"
  target                = google_compute_target_pool.yke_control_plane_target_pool.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}

# Firewall rule for load balancer health checks
resource "google_compute_firewall" "yke_lb_health_check" {
  name    = "yke-lb-health-check"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["yke-control-plane"]
}

# Traefik ingress load balancer
resource "google_compute_http_health_check" "yke_traefik_health_check" {
  name = "yke-traefik-health-check"
  
  port                = 80
  request_path        = "/ping"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_compute_target_pool" "yke_traefik_target_pool" {
  name = "yke-traefik-target-pool"
  
  instances = [
    for worker in google_compute_instance.yke_worker_node : worker.self_link
  ]
  
  health_checks = [
    google_compute_http_health_check.yke_traefik_health_check.name
  ]
}

resource "google_compute_forwarding_rule" "yke_traefik_forwarding_rule" {
  name                  = "yke-traefik-forwarding-rule"
  port_range            = "443"
  target                = google_compute_target_pool.yke_traefik_target_pool.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}

# Firewall rule for Traefik ingress traffic
resource "google_compute_firewall" "yke_traefik_ingress" {
  name    = "yke-traefik-ingress"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["yke-worker-node"]
}

# Firewall rule for Traefik health checks
resource "google_compute_firewall" "yke_traefik_health_check" {
  name    = "yke-traefik-health-check"
  network = google_compute_network.yke_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["yke-worker-node"]
}