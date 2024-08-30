terraform {
  backend "gcs" {
    bucket          = "inframarwan-bucket-terraform-state"
    prefix          = "terraform/state/stable"
    credentials     = "./precise-datum-433123-v6-ce9691445a3d.json"  # Remplacez par le chemin de votre clé JSON
  }
}
