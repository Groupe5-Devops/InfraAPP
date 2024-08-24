# InfraAPP

Infrastructure as Code (App-ManagerServer)

## Objectif

Créer deux instances Compute Engine sur Google Cloud Platform (GCP) en utilisant Terraform :
1. VM1 (Tooling) : Installer Docker, Docker Compose, Jenkins, Prometheus et Grafana
2. VM2 (APP) : Installer Minikube et ses dépendances

## Étapes de déploiement

1. **Prérequis**
   - Assurez-vous d'avoir Terraform installé
   - Configurez vos identifiants GCP et votre projet
   - Récupérez le fichier JSON de clé de compte de service GCP :
     - Allez sur la console GCP > IAM & Admin > Comptes de service
     - Créez un nouveau compte de service ou sélectionnez-en un existant
     - Générez une nouvelle clé au format JSON
     - Téléchargez le fichier JSON et placez-le dans un endroit sûr
   - Installez Ansible sur votre machine locale

2. **Cloner le dépôt**
    - git clone <url-du-dépôt>
    - cd InfraAPP
3. **Configuration de Terraform**
- Naviguez vers le répertoire Terraform (s'il n'est pas à la racine)
- Copiez le fichier JSON de clé GCP dans le répertoire Terraform
- Modifiez le fichier de variables Terraform pour pointer vers votre fichier JSON :
  ```
  # Dans terraform.tfvars
  gcp_credentials_file = "chemin/vers/votre-fichier-gcp.json"
  ```
4. **Exécuter le Script de Déploiement**
   Le script **deploy_infra.sh** automatise l'ensemble du processus de déploiement, y compris l'initialisation de Terraform, l'application de la configuration, la génération de l'inventaire et le déploiement des VMs avec Ansible. Utilisez-le comme suit :
   1. **Rendre le Script Exécutable (si nécessaire)** :
        
        chmod +x deploy_infra.sh

   2. **Exécuter le Script** : 
        
        ./deploy_infra.sh

  Le script deploy_infra.sh effectue les opérations suivantes :

      - Initialisation de Terraform : terraform init

      - Planification de l'Infrastructure : terraform plan -out=tfplan

      - Application de la Configuration Terraform : terraform apply -auto-approve tfplan

      - Génération de l'Inventaire : ./generate_inventaire_delete_ssholdips.sh

      - Création d'un Fichier de Configuration SSH Temporaire : Création et suppression automatique d'un fichier de configuration SSH temporaire pour les playbooks Ansible.
      
      - Déploiement des VMs :
            - VM Tooling : Installation et configuration de Docker, Docker Compose, Jenkins, Prometheus et Grafana.
                           ansible-playbook -i inventaire playbookTooling.yml
            
            - VM APP : Installation de Minikube et de ses dépendances.
                           ansible-playbook -i inventaire playbookAPP.yml

  ```
5. **Vérifier les installations**
- Connectez-vous en SSH à chaque VM pour vérifier les installations :
  - VM Tooling : Vérifiez Docker, Jenkins (port 8080), Prometheus (port 9090) et Grafana (port 3000)
  - VM APP : Vérifiez l'installation de Minikube

6. **Nettoyage (Optionnel)**
- Pour détruire l'infrastructure lorsqu'elle n'est plus nécessaire :
  ```
  terraform destroy
  ```

## Notes importantes

- Assurez-vous que tous les ports nécessaires sont ouverts dans les règles de pare-feu GCP (22, 8080, 9090, 3000)
- Le fichier `LICENSE.txt` contient des informations importantes sur la licence de Terraform
- En cas de problèmes ou de comportements inattendus, vérifiez les logs des services respectifs sur chaque VM
- Gardez votre fichier JSON de clé GCP en sécurité et ne le partagez jamais publiquement

## Contribution

Veuillez lire les directives de contribution avant de soumettre des modifications à ce projet.

## Licence

Ce projet utilise Terraform, qui est sous licence Business Source License. Consultez `LICENSE.txt` pour plus de détails.

