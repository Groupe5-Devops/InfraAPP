# InfraAPP

Infrastructure as Code (App-ManagerServer)

## Objectif

Déployer deux instances Compute Engine sur Google Cloud Platform (GCP) en utilisant Terraform :

1. **VM1 (Tooling)** : Docker, Docker Compose, Jenkins, Prometheus et Grafana
2. **VM2 (APP)** : Minikube et ses dépendances

## Prérequis

- Terraform installé
- Compte GCP configuré avec un projet actif
- Fichier JSON de clé de compte de service GCP
- Ansible installé sur la machine locale

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
  gcp_credentials_file = "chemin/vers/votre-fichier-gcp.json"

  ```

3. **Exécuter le script de déploiement**
```
chmod +x deploy_infra.sh
./deploy_infra.sh

```

## Étapes de déploiement

Le script `deploy_infra.sh` effectue automatiquement les opérations suivantes :

1. Initialisation de Terraform
2. Planification de l'infrastructure
3. Application de la configuration Terraform
4. Génération de l'inventaire Ansible
5. Configuration SSH temporaire
6. Déploiement des VMs avec Ansible:
- VM Tooling : Docker, Docker Compose, Jenkins, Prometheus, Grafana
- VM APP : Minikube et dépendances

## Vérification

- Connectez-vous en SSH à chaque VM pour vérifier les installations
- Ports à vérifier sur VM Tooling:
- Jenkins: 8080
- Prometheus: 9090
- Grafana: 3000

## Nettoyage

Pour détruire l'infrastructure :

terraform destroy

## Notes importantes

- Assurez-vous que les ports nécessaires (22, 8080, 9090, 3000) sont ouverts dans les règles de pare-feu GCP
- Consultez `LICENSE.txt` pour les informations de licence de Terraform
- En cas de problèmes, vérifiez les logs des services sur chaque VM
- Sécurisez votre fichier JSON de clé GCP et ne le partagez jamais publiquement

## Contribution

Veuillez consulter les directives de contribution avant de soumettre des modifications.

## Licence

Ce projet utilise Terraform, sous licence Business Source License. Voir `LICENSE.txt` pour plus de détails.