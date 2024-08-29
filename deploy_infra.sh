#!/bin/bash

# Fonction pour exécuter des commandes avec un message
run_command() {
    echo "Execution de : $1"
    eval $1
}

# Fonction pour vérifier la disponibilité des instances
check_instance_availability() {
    local instance_ips=("$@")
    for ip in "${instance_ips[@]}"; do
        echo "verification de l'instance avec IP $ip..."
        while ! nc -zv $ip 22; do
            echo "En attente que l'instance $ip soit prete..."
            sleep 10
        done
        echo "Instance $ip est prete."
    done
}

# Définir les variables
HOSTS_FILE="inventaire"
TF_OUTPUT_JSON_FILE="terraform_output.json"

# Détecter le chemin du répertoire utilisateur
USER_HOME=$(eval echo ~$USER)
SSH_KEY_PATH="$USER_HOME/.ssh/id_rsa"

# Génerer dynamiqument un metadata pour les SSH-KEYS sur les VMs

run_command "./generate_ssh_keys.sh"

# Initialisation de Terraform
run_command "terraform init"

# Planification de l'infrastructure
run_command "terraform plan -out=tfplan"

# Application de la configuration Terraform sans confirmation
run_command "terraform apply -auto-approve tfplan"

# Appeler le script de generation d'inventaire
run_command "./generate_inventaire_delete_ssholdips.sh"

# Obtenir les adresses IP des instances depuis le fichier JSON genere par le script
IP_ADDRESSES=$(jq -r '.[]' $TF_OUTPUT_JSON_FILE)

# Convertir les IP en tableau
IP_ARRAY=($IP_ADDRESSES)

# Verifiez le nombre d'IP extraites
if [ ${#IP_ARRAY[@]} -lt 2 ]; then
    echo "Erreur : Pas assez d'adresses IP trouvees dans le fichier JSON."
    exit 1
fi

# Vérifier que les instances sont pretes
check_instance_availability "${IP_ARRAY[@]}"

# Définir les options SSH pour Ansible
export ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $SSH_KEY_PATH"

# Déploiement de la VM Tooling avec les options SSH personnalisees
run_command "ansible-playbook -i $HOSTS_FILE playbookTooling.yml"

# Déploiement de la VM APP avec les options SSH personnalisees
run_command "ansible-playbook -i $HOSTS_FILE playbookAPP.yml"

echo "Deploiement termine."
