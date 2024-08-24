#!/bin/bash

# Fonction pour exécuter des commandes avec un message
run_command() {
    echo "Execution de : $1"
    eval $1
}

# Initialisation de Terraform
run_command "terraform init"

# Planification de l'infrastructure
run_command "terraform plan -out=tfplan"

# Application de la configuration Terraform sans confirmation
run_command "terraform apply -auto-approve tfplan"

# Generation de l'inventaire et suppression des anciennes cles SSH
run_command "./generate_inventaire_delete_ssholdips.sh"

# Creer un fichier de configuration SSH temporaire
SSH_CONFIG_FILE=$(mktemp)
cat << EOF > $SSH_CONFIG_FILE
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

# Deploiement de la VM Tooling avec la configuration SSH personnalisee
run_command "ANSIBLE_SSH_ARGS='-F $SSH_CONFIG_FILE' ansible-playbook -i inventaire playbookTooling.yml"

# Deploiement de la VM APP avec la configuration SSH personnalisee
run_command "ANSIBLE_SSH_ARGS='-F $SSH_CONFIG_FILE' ansible-playbook -i inventaire playbookAPP.yml"

# Supprimer le fichier de configuration SSH temporaire
rm $SSH_CONFIG_FILE

echo "Deploiement Done."