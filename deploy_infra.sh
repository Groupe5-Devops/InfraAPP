#!/bin/bash

# Fonction pour exécuter des commandes avec un message
run_command() {
    echo "Execution de : $1"
    eval $1
}

# Génerer dynamiqument un metadata pour les SSH-KEYS sur les VMs

run_command "./generate_ssh_keys.sh"

# Initialisation de Terraform
run_command "terraform init"

# Planification de l'infrastructure
run_command "terraform plan -out=tfplan"

# Application de la configuration Terraform sans confirmation
run_command "terraform apply -auto-approve tfplan"

echo "Deploiement termine."
