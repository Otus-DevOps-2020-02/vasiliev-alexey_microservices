provider "google" {
  version = "~> 2.15"
  project = var.project
  region  = var.region
}

#Creating VM instance for App server
module "docker" {
  source           = "../modules/docker"
  public_key_path  = var.public_key_path
  zone             = var.zone
  host_disk_image   = var.host_disk_image
  private_key_path = var.private_key_path
  provision_count  = var.provision_count
}

#module "vpc" {
#  source        = "../modules/vpc"
#  source_ranges = ["0.0.0.0/0"]
#}
