resource "google_compute_network" "yke_vpc" {
  name                    = "yke-vpc"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

resource "google_compute_subnetwork" "yke_public_subnet" {
  name          = "yke-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  network       = google_compute_network.yke_vpc.id
  region        = var.region
}

resource "google_compute_router" "yke_router" {
  name    = "yke-router"
  region  = var.region
  network = google_compute_network.yke_vpc.id
}

resource "google_compute_router_nat" "yke_nat" {
  name                               = "yke-nat"
  router                             = google_compute_router.yke_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}