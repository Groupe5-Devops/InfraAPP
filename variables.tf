variable "gcp_project" {
  description = "GCP Project ID"
  type        = string  
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
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
}