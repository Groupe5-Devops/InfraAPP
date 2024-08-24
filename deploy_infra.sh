#!/bin/bash

# Fonction pour exécuter des commandes avec un message
run_command() {
    echo "Execution de : $1"
    eval $1
}

# Détecter le chemin du répertoire utilisateur
USER_HOME=$(eval echo ~$USER)
SSH_KEY_PATH="$USER_HOME/.ssh/id_rsa"

# Initialisation de Terraform
run_command "terraform init"

# Planification de l'infrastructure
run_command "terraform plan -out=tfplan"

# Application de la configuration Terraform sans confirmation
run_command "terraform apply -auto-approve tfplan"

# Generation de l'inventaire et suppression des anciennes cles SSH
run_command "./generate_inventaire_delete_ssholdips.sh"

# Attendre que les instances soient prêtes (ajustez le temps si nécessaire)
echo "Attente de 60 secondes pour que les instances soient pretes..."
sleep 60

# Définir les options SSH pour Ansible
ANSIBLE_SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY_PATH"

# Deploiement de la VM Tooling avec les options SSH personnalisees
run_command "ANSIBLE_SSH_ARGS='$ANSIBLE_SSH_OPTS' ansible-playbook -i inventaire playbookTooling.yml"

# Deploiement de la VM APP avec les options SSH personnalisees
run_command "ANSIBLE_SSH_ARGS='$ANSIBLE_SSH_OPTS' ansible-playbook -i inventaire playbookAPP.yml"

echo "Deploiement Done."