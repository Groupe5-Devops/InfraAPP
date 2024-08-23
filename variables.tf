variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
  default     = "citric-period-433211-i6"
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}

variable "vm_machine_type" {
  description = "Machine type for the VMs"
  type        = string
  default     = "n2-standard-2"
}

variable "vm_os_image" {
  description = "OS image for the VMs"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "credentials_file" {
  description = "Path to the service account key file"
  type        = string
  default     = "./citric-period-433211-i6-99010435d1d3.json"
}