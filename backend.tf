terraform {
  backend "gcs" {
    bucket          = "infrasimul-bucket-terraform-state"
    prefix          = "terraform/state"
    credentials     = "./keen-ally-433123-d4-931a055f940d.json"  # Remplacez par le chemin de votre clé JSON
  }
}
