#!/bin/bash

# Définir les variables
HOSTS_FILE="inventaire"
TF_OUTPUT_JSON_FILE="terraform_output.json"

# Détecter le chemin du répertoire utilisateur
USER_HOME=$(eval echo ~$USER)
SSH_KEY_PATH="$USER_HOME/.ssh/id_rsa"

# Vérifier si jq est installé
if ! command -v jq &> /dev/null; then
  echo "jq n'est pas installé. Installation en cours..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jq
fi

# Obtenir les adresses IP des instances au format JSON
terraform output -json vm_static_ips > $TF_OUTPUT_JSON_FILE

# Extraire les adresses IP du fichier JSON
IP_ADDRESSES=$(jq -r '.[]' $TF_OUTPUT_JSON_FILE)

# Convertir les IP en tableau
IP_ARRAY=($IP_ADDRESSES)

# Vérifiez le nombre d'IP extraites
if [ ${#IP_ARRAY[@]} -lt 2 ]; then
  echo "Erreur : Pas assez d'adresses IP trouvées dans le fichier JSON."
  exit 1
fi

# Générer le fichier d'inventaire
echo "[Tooling]" > $HOSTS_FILE
echo "${IP_ARRAY[0]} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH}" >> $HOSTS_FILE
echo "[APP]" >> $HOSTS_FILE
echo "${IP_ARRAY[1]} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH}" >> $HOSTS_FILE

echo "Fichier d'inventaire généré : $HOSTS_FILE"

# Supprimer les anciennes clés SSH pour chaque IP sans demander de confirmation
for IP in "${IP_ARRAY[@]}"; do
  echo "Suppression de l'ancienne clé SSH pour $IP"
  ssh-keygen -R "$IP" -f "$USER_HOME/.ssh/known_hosts" 2>/dev/null
done

echo "Toutes les anciennes clés SSH ont été supprimées."