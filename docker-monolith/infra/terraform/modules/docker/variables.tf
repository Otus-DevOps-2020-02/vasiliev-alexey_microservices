variable host_disk_image {
  description = "Disk image for docker-app"
  default     = "docker-host-base"
}
variable "zone" {
  default = "europe-west1-b"
}
variable "public_key_path" {
  description = "~/.ssh/appuser.pub"
}
variable "private_key_path" {
  description = "~/.ssh/appuser"
}
variable provision_count {
  description = "Количество инстансов"
}
variable counter {
  description = 2
  default     =2
}
