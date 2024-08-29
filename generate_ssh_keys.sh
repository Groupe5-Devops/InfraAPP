#!/bin/bash

# R�pertoire o� se trouvent les cl�s SSH publiques
ssh_dir="$HOME/.ssh"

# Chemin du fichier de sortie
output_file="./generated_ssh_keys.txt"

# Vider ou cr�er le fichier de sortie
: > "$output_file"

# Boucle sur chaque fichier .pub dans le r�pertoire .ssh
for pubkey in "$ssh_dir"/*.pub; do
  # Extraire la ligne de la cl� SSH (derni�re colonne)
  user_info=$(awk '{print $NF}' "$pubkey")
  
  # Extraire le nom d'utilisateur avant le symbole @
  username=$(echo "$user_info" | cut -d'@' -f1)
  
  # Ajouter la ligne format�e au fichier de sortie
  echo "$username: $(cat "$pubkey")" >> "$output_file"
done