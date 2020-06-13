terraform {
  required_version = ">= 0.12.17"
}

provider "google" {
  version = "~> 3.0.0"
  project = var.project
  region  = var.region
}

provider "google-beta" {
  version = "~> 3.0.0"
  project = var.project
  region  = var.region
}

resource "google_container_cluster" "kub" {
  name     = "kub"
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 2

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  location   = var.location
  cluster    = google_container_cluster.kub.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 20
    tags          = ["app"]
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_firewall" "kub-default" {
  name    = "kub-default"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["app"]
  direction     = "INGRESS"
  priority      = "1000"
}
