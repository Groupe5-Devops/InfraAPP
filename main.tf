# Provider Google Cloud
provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  credentials = file(var.credentials_file)
}

# Création du bucket GCS pour la sauvegarde de la base de données MySQL
resource "google_storage_bucket" "mysql_backup" {
  name          = "inframarwan-mysql-backup-bucket"
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

# Création du réseau VPC pour les VMs
resource "google_compute_network" "vm_network" {
  name = "vm-network"
}

# Création du sous-réseau pour les VMs
resource "google_compute_subnetwork" "vm_subnet" {
  name          = "vm-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vm_network.name
}

# Création de la règle de pare-feu pour autoriser tout le trafic
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

# Création d'adresses IP statiques pour les VMs
resource "google_compute_address" "vm_ip" {
  count  = var.vm_count
  name   = "vm-ip-${count.index + 1}"
  region = var.gcp_region
}

# Lecture du contenu du fichier généré pour les clés SSH
data "local_file" "ssh_keys_file" {
  filename = "${path.module}/generated_ssh_keys.txt"
}

# Création des instances de VMs
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
  
  tags = ["vm", "vm-${count.index + 1}"]
}

# Création du dépôt Artifact Registry pour AppManager
resource "google_artifact_registry_repository" "appmanagercr" {
  location      = "us-central1"
  repository_id = "appmanagercr"
  description   = "Docker repository for AppManagerServer"
  format        = "DOCKER"
}

# --------- Cloud Function, Bucket GCS, Scheduler Jobs et Invoker ---------

# Création du bucket pour stocker le code de la fonction
resource "google_storage_bucket" "function_bucket" {
  name                        = "controlvm-testmarwan-function-bucket"
  location                    = var.gcp_region
  force_destroy               = true
  uniform_bucket_level_access = true

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

# Ressource factice pour exécuter Ansible avant de créer la Cloud Function
resource "null_resource" "ansible_preparation" {
  provisioner "local-exec" {
    command = "ansible-playbook -i inventaire deploy_function.yml"  # Commande pour exécuter le playbook Ansible
  }

  triggers = {
    always_run = "${timestamp()}"  # Utilise un horodatage pour toujours déclencher la ressource
  }
}

# Création de la Cloud Function pour contrôler les VM
resource "google_cloudfunctions_function" "vm_control_function" {
  depends_on = [null_resource.ansible_preparation]

  name        = "vm-control-function"
  description = "Fonction pour contrôler la VM"
  runtime     = "python39"

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = "function.zip"
  trigger_http          = true
  entry_point           = "control_vm"

  environment_variables = {
    PROJECT_ID    = var.gcp_project
    INSTANCE_NAME = "vm-2"
    ZONE          = "${var.gcp_region}-a"
  }
}

# Ajout du rôle invoker à la Cloud Function pour le compte de service des jobs Cloud Scheduler
resource "google_cloudfunctions_function_iam_member" "invoker_scheduler" {
  project        = var.gcp_project
  region         = var.gcp_region
  cloud_function = google_cloudfunctions_function.vm_control_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${var.gcp_project}@appspot.gserviceaccount.com"  # Compte de service par défaut pour Cloud Scheduler
}

# Création des jobs Cloud Scheduler pour démarrer et arrêter la VM
resource "google_cloud_scheduler_job" "vm_start_job" {
  name      = "vm-start-job"
  schedule  = "50 7 * * 1-5"  # 7h50 du lundi au vendredi (heure du Maroc)
  time_zone = "Africa/Casablanca"

  http_target {
    http_method = "POST"
    uri         = "${google_cloudfunctions_function.vm_control_function.https_trigger_url}?action=start"

    # Utilisation du compte de service pour authentifier l'appel
    oidc_token {
      service_account_email = "${var.gcp_project}@appspot.gserviceaccount.com"
      audience              = google_cloudfunctions_function.vm_control_function.https_trigger_url
    }
  }
}

resource "google_cloud_scheduler_job" "vm_stop_job" {
  name      = "vm-stop-job"
  schedule  = "10 21 * * 1-5"  # 21h10 du lundi au vendredi (heure du Maroc)
  time_zone = "Africa/Casablanca"

  http_target {
    http_method = "POST"
    uri         = "${google_cloudfunctions_function.vm_control_function.https_trigger_url}?action=stop"

    # Utilisation du compte de service pour authentifier l'appel
    oidc_token {
      service_account_email = "${var.gcp_project}@appspot.gserviceaccount.com"
      audience              = google_cloudfunctions_function.vm_control_function.https_trigger_url
    }
  }
}


# --------- Outputs ---------

output "vm_static_ips" {
  value       = [for instance in google_compute_instance.vm : instance.network_interface[0].access_config[0].nat_ip]
  description = "Les adresses IP statiques assignées aux VMs."
}

output "function_url" {
  value       = google_cloudfunctions_function.vm_control_function.https_trigger_url
  description = "URL de déclenchement de la Cloud Function"
}

output "bucket_name" {
  value       = google_storage_bucket.function_bucket.name
  description = "Nom du bucket de stockage pour la fonction"
}
