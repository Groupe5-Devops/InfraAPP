provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = file(var.credentials_file)
}

# Crée un réseau VPC
resource "google_compute_network" "vm_network" {
  name = "vm-network"
}

# Crée un sous-réseau
resource "google_compute_subnetwork" "vm_subnet" {
  name          = "vm-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vm_network.name
}

# Crée une règle de pare-feu pour autoriser le trafic SSH
resource "google_compute_firewall" "vm_firewall_ssh" {
  name    = "vm-firewall-ssh"
  network = google_compute_network.vm_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Crée une règle de pare-feu pour autoriser le trafic sur les ports 8080, 9090 et 3000
resource "google_compute_firewall" "vm_firewall_ports" {
  name    = "vm-firewall-ports"
  network = google_compute_network.vm_network.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "9090", "3000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Crée des adresses IP statiques
resource "google_compute_address" "vm_ip" {
  count  = var.vm_count
  name   = "vm-ip-${count.index + 1}"
  region = var.gcp_region
}

# Crée un disque persistant de 40 Go pour chaque instance
#resource "google_compute_disk" "vm_disk" {
#  count  = var.vm_count
#  name   = "vm-disk-${count.index + 1}"
#  size   = 40
#  type   = "pd-standard" # Vous pouvez aussi utiliser "pd-ssd" pour SSD
#  zone   = "${var.gcp_region}-a"
#}

# Crée des machines virtuelles
resource "google_compute_instance" "vm" {
  count        = var.vm_count
  name         = "vm-${count.index + 1}"
  machine_type = var.vm_machine_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = var.vm_os_image
      size  = 40
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vm_network.name
    subnetwork = google_compute_subnetwork.vm_subnet.name
    access_config {
      nat_ip = google_compute_address.vm_ip[count.index].address
    }
  }
  
  metadata_startup_script = file("install_ansible.sh")

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  tags = ["vm"]
}

# Output les IPs statiques des vms
output "vm_static_ips" {
  value = [
    for instance in google_compute_instance.vm : instance.network_interface[0].access_config[0].nat_ip
  ]
  description = "Les adresses IP statiques assignées aux vms."
}