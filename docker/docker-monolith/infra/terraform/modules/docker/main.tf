resource "google_compute_instance" "docker-host" {
  count        = var.counter
  name         = "docker-host-${count.index+1}"
  machine_type = "f1-micro"
  zone         = var.zone
  tags         = ["docker-host-${count.index+1}"]


  boot_disk {
    initialize_params {
      image = "${var.host_disk_image}"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "null_resource" "docker_provisioner" {
  count = var.provision_count
  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
    host        = "${google_compute_instance.docker-app.network_interface.0.access_config.0.nat_ip}"
  }

}

resource "google_compute_firewall" "firewall_puma" {
  count = var.counter
  name = "allow-docker-app-${count.index+1}"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["docker-host-${count.index+1}"]
}
