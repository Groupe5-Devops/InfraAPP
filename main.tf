provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = file(var.credentials_file)
}

# Création du bucket GCS pour la sauvegarde de la base de données MySQL
resource "google_storage_bucket" "mysql_backup" {
  name          = "infra-mysql-backup-bucket"
  location      = var.gcp_region
  force_destroy = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
  
  versioning {
    enabled = true
  }
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

# Crée une règle de pare-feu pour autoriser tout le trafic
resource "google_compute_firewall" "allow_all" {
  name    = "allow-all"
  network = google_compute_network.vm_network.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

# Crée des adresses IP statiques
resource "google_compute_address" "vm_ip" {
  count  = var.vm_count
  name   = "vm-ip-${count.index + 1}"
  region = var.gcp_region
}

# Lire le contenu du fichier généré
data "local_file" "ssh_keys_file" {
  filename    = "${path.module}/generated_ssh_keys.txt"
}

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
  
  metadata = {
    "ssh-keys" = <<EOF
${data.local_file.ssh_keys_file.content}
EOF
  }
  
  # Assignation des tags appropriés
  tags = ["vm", "vm-${count.index + 1}"]
}

# Création du dépôt Artifact Registry
resource "google_artifact_registry_repository" "appmanagercr" {
  location      = "us-central1"
  repository_id = "appmanagercr"
  description   = "Docker repository for AppManagerServer"
  format        = "DOCKER"
}

# Output les IPs statiques des vms
output "vm_static_ips" {
  value = [
    for instance in google_compute_instance.vm : instance.network_interface[0].access_config[0].nat_ip
  ]
  description = "Les adresses IP statiques assignées aux vms."
}
