variable "project_id" {
  type        = string
  description = "GCP project ID"
  default     = "yoofi-sandbox"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "us-central1-c"
}

variable "vpc_cidr_range" {
  type        = string
  description = "CIDR range of the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR"
  default     = "10.0.1.0/24"
}

variable "control_plane_machine_type" {
  type        = string
  description = "Machine type for control plane nodes"
  default     = "e2-standard-2"
}

variable "worker_node_machine_type" {
  type        = string
  description = "Machine type for worker nodes"
  default     = "e2-standard-2"
}

variable "worker_node_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 2
}

variable "ubuntu_image" {
  type        = string
  description = "Ubuntu image to use"
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "boot_disk_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 20
}

variable "boot_disk_type" {
  type        = string
  description = "Boot disk type"
  default     = "pd-standard"
}

variable "gce_ssh_user" {
  type        = string
  description = "GCE SSH user"
  default     = "ybquansah"
}

variable "gce_ssh_pub_key_file" {
  type        = string
  description = "GCE SSH public key file"
  default     = "~/.ssh/id_rsa.pub"
}
