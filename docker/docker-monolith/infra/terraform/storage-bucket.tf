provider "google" {
 version = "~> 2.15"
 project = var.project
 region  = var.region
 zone    = var.zone
}

module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "~> 0.3.0"

  location = var.region
  # Имя поменяйте на другое
  name = "sb-otus-devops-av"

}

output storage-bucket_url {
  value = module.storage-bucket.url
}
