# InfraAPP

Infrastructure as a Code (App-ManagerServer)

## Objectif

Déploiment sur Google Cloud Platform (GCP) en utilisant Terraform de :

1. **VM1 (Tooling)** qui va contenir Docker, Docker Compose, Jenkins,Ansible et Terraform ( outils config Ansible).
2. **VM2 (APP)** qui contienndra Microk8s et ses dépendances ( outils config Ansible).
3. Création du dépôt Artifact Registry.
4. Création du bucket GCS pour la sauvegarde de la base de données MySQL.

## Prérequis
- Ios ubuntu 22.04
- Compte GCP configuré avec un projet actif
- Fichier JSON de clé de compte de service GCP
- Terraform installé sur la machine locale
- Ansible installé sur la machine locale
- Création d'un Bucket de Google Cloud Storage pour le ".tfstate" nommé "infra-bucket-terraform-state".
    N.B : passer par https://console.cloud.google.com/storage.
- Générer une paire de clés SSH, vous pouvez utiliser la commande suivante :

     ssh-keygen -t rsa -b 4096 -C "utilisateur@example.com"

      N.B : Respecter impérativement ce format . exemple utilisateur : ubuntu ou votre nom ....
            Pour ces parametres appuyer sur Entrée
            
            Enter file in which to save the key (/home/votre_user/.ssh/id_rsa): 
            Enter passphrase (empty for no passphrase):
            Enter same passphrase again:


## Installation

1. **Cloner le dépôt**
```
  git clone <url-du-dépôt>
  cd InfraAPP
```
2. **Configurer Terraform**
- Copiez le fichier JSON de clé GCP dans le répertoire Terraform
- Creer un fichier `terraform.tfvars` avec :

  ```
  gcp_project            = "id_project"
  gcp_region             = "exemple_us-central1"
  gcp_credentials_file = "./chemin/vers/votre-fichier-gcp.json"

  ```
- Modifier le fichier backend.tf 
  
  ```
    bucket          = "infra-bucket-terraform-state"
    prefix          = "terraform/state/stable"
    credentials     = "./chemin/vers/votre-fichier-gcp.json"
 
  ```
  
3. **Exécuter le script de déploiement **
```
chmod +x deploy_infra.sh
./deploy_infra.sh

```

## Étapes de déploiement

Le script `deploy_infra.sh` effectue automatiquement les opérations suivantes :

  - Génerer dynamiquement un metadata pour les SSH-KEYS sur les VMs
  - Initialisation de Terraform
  - Planification de l'infrastructure
  - Application de la configuration Terraform

4. **Exécuter le script de configuration avec Ansible **
```

chmod +x install_config.sh
./install_config.sh

```

Le script `install_config.sh` effectue automatiquement les opérations suivantes :

1. Génération de l'inventaire Ansible
2. Configuration SSH.
3. Déploiement des VMs avec Ansible:

      - VM Tooling : Docker, Docker Compose, Jenkins,Ansible et Terraform.
      - VM APP : Microk8s et dépendances.

NB: S'assurer que tous les fichiers .sh sont exécutables.


## Ports ouverts sur le firewall GCP

- Connectez-vous en SSH à chaque VM pour vérifier les installations

- Ports à vérifier sur VM Tooling:
- Jenkins: 8080

- Ports à ouvrir sur VM APP:

- Prometheus: 9090
- Grafana: 3000
- Server-Manager : 30004

## Nettoyage

Pour détruire l'infrastructure :

terraform destroy

## Notes importantes

- Assurez-vous que les ports nécessaires (22, 8080, 9090, 3000,30004) sont ouverts dans les règles de pare-feu GCP 
- Consultez `LICENSE.txt` pour les informations de licence de Terraform
- En cas de problèmes, vérifiez les logs des services sur chaque VM
- Sécurisez votre fichier JSON de clé GCP et ne le partagez jamais publiquement

## Contribution

Veuillez consulter les directives de contribution avant de soumettre des modifications.

## Licence

Ce projet utilise Terraform, sous licence Business Source License. Voir `LICENSE.txt` pour plus de détails.