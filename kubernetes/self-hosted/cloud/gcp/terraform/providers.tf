terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.43.0"
    }
  }
}

# Configure the GCP Provider
provider "google" {
  project = "yoofi-sandbox"
  region  = "us-central1"
  zone    = "us-central1-a"
}