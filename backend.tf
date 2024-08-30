terraform {
  backend "gcs" {
    bucket          = "infra-bucket-terraform-state"
    prefix          = "terraform/state/stable"
    credentials     = "./citric-period-433211-i6-99010435d1d3.json"  # Remplacez par le chemin de votre clé JSON
  }
}
