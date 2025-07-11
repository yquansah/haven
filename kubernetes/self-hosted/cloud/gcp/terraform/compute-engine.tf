resource "google_compute_instance" "yke_control_plane" {
  name         = "yke-control-plane-0"
  machine_type = var.control_plane_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.ubuntu_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.yke_public_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  tags = ["yke-control-plane"]

  service_account {
    email  = google_service_account.yke_control_plane_sa.email
    scopes = ["cloud-platform"]
  }

  labels = {
    component = "control-plane-node"
  }

  can_ip_forward = true
}

resource "google_compute_instance" "yke_worker_node" {
  count        = var.worker_node_count
  name         = "yke-worker-${count.index}"
  machine_type = var.worker_node_machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.ubuntu_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.yke_public_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  tags = ["yke-worker-node"]

  service_account {
    email  = google_service_account.yke_worker_node_sa.email
    scopes = ["cloud-platform"]
  }

  labels = {
    component = "worker-node"
  }

  can_ip_forward = true
}

resource "google_service_account" "yke_control_plane_sa" {
  account_id   = "yke-control-plane-sa"
  display_name = "YKE Control Plane Service Account"
}

resource "google_service_account" "yke_worker_node_sa" {
  account_id   = "yke-worker-node-sa"
  display_name = "YKE Worker Node Service Account"
}

resource "google_project_iam_member" "yke_control_plane_sa_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.yke_control_plane_sa.email}"
}

resource "google_project_iam_member" "yke_worker_node_sa_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.yke_worker_node_sa.email}"
}

resource "google_project_iam_member" "yke_control_plane_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.yke_control_plane_sa.email}"
}

resource "google_project_iam_member" "yke_worker_node_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.yke_worker_node_sa.email}"
}
