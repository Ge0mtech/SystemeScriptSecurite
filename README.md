# 🛡️ Système, Scripts et Sécurité

Projet complet d'administration système et de sécurisation de scripts bash avec exploitation d'API, surveillance système et automatisation des tâches.

## 📋 Sommaire du projet

1. [Configuration environnement](#1-configuration-environnement)
2. [Commandes de recherche avancée](#2-commandes-de-recherche-avancée)
3. [Compression et archivage](#3-compression-et-archivage)
4. [Manipulation de texte](#4-manipulation-de-texte)
5. [Gestion des processus](#5-gestion-des-processus)
6. [Surveillance des ressources](#6-surveillance-des-ressources)
7. [Scripts de sauvegarde](#7-scripts-de-sauvegarde)
8. [Automatisation système](#8-automatisation-système)
9. [Gestion des dépendances](#9-gestion-des-dépendances)
10. [Sécurisation des scripts](#10-sécurisation-des-scripts)
11. [API Web sécurisée](#11-api-web-sécurisée)

---

## 1. Configuration environnement

### VM Debian - Configuration initiale
- **VM Debian** avec interface graphique
- **Nom de session :** La_Plateforme
- **Mot de passe :** LAPlateforme_
- **Architectures supportées :** AMD64 / ARM64

### Prérequis système
```bash
# Vérification de la connectivité réseau
ping -c 3 google.com

# Mise à jour initiale
sudo apt update && sudo apt upgrade -y
```

---

## 2. Commandes de recherche avancée

### Création des fichiers de test
Créer 5 fichiers "mon_texte.txt" contenant "Que la force soit avec toi." dans différents répertoires.

```bash
# Script de création automatique
for dir in Bureau Documents Téléchargements Vidéos Images; do
    echo "Que la force soit avec toi." > ~/"$dir"/mon_texte.txt
done
```

### Recherche avec le mot "force"
```bash
# Localiser tous les fichiers contenant "force"
find ~/ -name "mon_texte.txt" -exec grep -l "force" {} \;
```

**Résultat attendu :** 5 fichiers trouvés dans les répertoires spécifiés.

---

## 3. Compression et archivage

### Création du répertoire "Plateforme"
```bash
# Créer le répertoire et dupliquer les fichiers
mkdir -p ~/Documents/Plateforme
for i in {1..4}; do 
    cp ~/Documents/mon_texte.txt ~/Documents/Plateforme/mon_texte_$i.txt
done
cp ~/Documents/mon_texte.txt ~/Documents/Plateforme/
```

### Archivage avec tar et gzip
```bash
# Compression avec différentes options
tar czvf Plateforme.tar.gz -C ~/Documents Plateforme     # Compression gzip
tar cjvf Plateforme.tar.bz2 -C ~/Documents Plateforme    # Compression bzip2
tar cJvf Plateforme.tar.xz -C ~/Documents Plateforme     # Compression xz
```

### Décompression
```bash
# Décompression selon le format
tar xzvf Plateforme.tar.gz     # gzip
tar xjvf Plateforme.tar.bz2    # bzip2
tar xJvf Plateforme.tar.xz     # xz
```

---

## 4. Manipulation de texte

### Script Python pour générer un CSV
```python
# generer_csv.py
import csv

data = [
    ["Nom", "Age", "Ville"],
    ["Jean", 25, "Paris"],
    ["Marie", 30, "Lyon"],
    ["Pierre", 22, "Marseille"],
    ["Sophie", 35, "Toulouse"]
]

with open("data.csv", "w", newline="", encoding="utf-8") as fichier:
    writer = csv.writer(fichier)
    writer.writerows(data)

print("Fichier CSV créé avec succès !")
```

### Extraction avec awk
```bash
# Exécuter le script Python
python3 generer_csv.py

# Extraire la colonne "Ville" (3ème colonne)
awk -F, 'NR > 1 {print $3}' data.csv
```

**Résultat :**
```
Paris
Lyon
Marseille
Toulouse
```

---

## 5. Gestion des processus

### Lister les processus actifs
```bash
# Voir tous les processus
ps aux

# Processus en temps réel
top
htop  # Plus moderne et interactif
```

### Terminer un processus
```bash
# Terminaison normale (SIGTERM)
kill PID

# Terminaison par nom de processus
pkill nom_processus

# Terminaison forcée (SIGKILL)
kill -9 PID
kill -KILL PID

# Terminaison forcée par nom
pkill -9 nom_processus
```

### Différences entre terminaisons
- **SIGTERM (kill)** : Permet au processus de se terminer proprement
- **SIGKILL (kill -9)** : Terminaison immédiate sans nettoyage

---

## 6. Surveillance des ressources

### Script de surveillance temps réel
```bash
#!/bin/bash

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher un en-tête coloré
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    COLLECTE DES STATISTIQUES SYSTÈME    ${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Fonction pour afficher les statistiques en temps réel
print_stats() {
    local timestamp="$1"
    local cpu_user="$2"
    local cpu_system="$3"
    local cpu_idle="$4"
    local memory_free="$5"
    local memory_used="$6"
    local disk_read="$7"
    local disk_write="$8"
    local network_in="$9"
    local network_out="${10}"
    
    echo -e "\n${GREEN}📊 Mesure à: ${timestamp}${NC}"
    echo -e "${YELLOW}CPU:${NC}"
    echo -e "  User: ${cpu_user}% | System: ${cpu_system}% | Idle: ${cpu_idle}%"
    echo -e "${YELLOW}Mémoire (KB):${NC}"
    echo -e "  Libre: ${memory_free} | Utilisée: ${memory_used}"
    echo -e "${YELLOW}Disque (KB/s):${NC}"
    echo -e "  Lecture: ${disk_read} | Écriture: ${disk_write}"
    echo -e "${YELLOW}Réseau (packets):${NC}"
    echo -e "  Entrée: ${network_in} | Sortie: ${network_out}"
    echo -e "${BLUE}----------------------------------------${NC}"
}

# Créer le répertoire de sortie s'il n'existe pas
mkdir -p logs

# Nom du fichier avec timestamp
csv_file="logs/stats_$(date +%Y%m%d_%H%M%S).csv"

# En-tête du fichier CSV avec descriptions
cat > "$csv_file" << EOF
# Statistiques système collectées le $(date)
# Format: Timestamp,CPU_User_%,CPU_System_%,CPU_Idle_%,Memory_Free_KB,Memory_Used_KB,Disk_Read_KB/s,Disk_Write_KB/s,Network_In_packets,Network_Out_packets
Timestamp,CPU User (%),CPU System (%),CPU Idle (%),Memory Free (KB),Memory Used (KB),Disk Read (KB/s),Disk Write (KB/s),Network In (packets),Network Out (packets)
EOF

# Afficher l'en-tête
print_header
echo -e "${GREEN}📁 Fichier de sortie: ${csv_file}${NC}"
echo -e "${GREEN}🔄 Collecte de 5 échantillons...${NC}\n"

# Boucle pour capturer les données
for i in {1..5}; do
    echo -e "${BLUE}Collecte ${i}/5...${NC}"
    
    # Obtenir les statistiques CPU et mémoire
    vmstat_output=$(vmstat 1 1)
    cpu_user=$(echo "$vmstat_output" | awk 'NR==3 {print $13}')
    cpu_system=$(echo "$vmstat_output" | awk 'NR==3 {print $14}')
    cpu_idle=$(echo "$vmstat_output" | awk 'NR==3 {print $15}')
    memory_free=$(echo "$vmstat_output" | awk 'NR==3 {print $4}')
    memory_used=$(echo "$vmstat_output" | awk 'NR==3 {print $3}')

    # Obtenir les statistiques de disque (avec gestion d'erreur)
    if command -v iostat >/dev/null 2>&1; then
        iostat_output=$(iostat -d 1 1 2>/dev/null)
        disk_read=$(echo "$iostat_output" | awk 'NR==4 {print $3}' 2>/dev/null || echo "N/A")
        disk_write=$(echo "$iostat_output" | awk 'NR==4 {print $4}' 2>/dev/null || echo "N/A")
    else
        disk_read="N/A"
        disk_write="N/A"
    fi

    # Obtenir les statistiques réseau
    netstat_output=$(netstat -i 2>/dev/null)
    network_in=$(echo "$netstat_output" | awk 'NR==4 {print $4}' 2>/dev/null || echo "N/A")
    network_out=$(echo "$netstat_output" | awk 'NR==4 {print $8}' 2>/dev/null || echo "N/A")

    # Timestamp formaté
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Afficher les statistiques en temps réel
    print_stats "$timestamp" "$cpu_user" "$cpu_system" "$cpu_idle" "$memory_free" "$memory_used" "$disk_read" "$disk_write" "$network_in" "$network_out"
    
    # Écrire dans le fichier CSV
    echo "$timestamp,$cpu_user,$cpu_system,$cpu_idle,$memory_free,$memory_used,$disk_read,$disk_write,$network_in,$network_out" >> "$csv_file"

    # Attendre avant la prochaine capture (sauf pour la dernière)
    if [ $i -lt 5 ]; then
        sleep 1
    fi
done

echo -e "\n${GREEN}✅ Collecte terminée!${NC}"
echo -e "${GREEN}📊 Résultats sauvegardés dans: ${csv_file}${NC}"

# Affichage du résumé final
echo -e "\n${YELLOW}📋 RÉSUMÉ:${NC}"
echo -e "Nombre d'échantillons: 5"
echo -e "Fichier CSV: ${csv_file}"
echo -e "Taille du fichier: $(du -h "$csv_file" | cut -f1)"

# Option pour visualiser le CSV
echo -e "\n${BLUE}💡 Pour visualiser les données:${NC}"
echo -e "   column -t -s, '$csv_file' | head -10"
echo -e "   ou"
echo -e "   cat '$csv_file'"
```

### Commandes de surveillance en temps réel
```bash
# CPU et mémoire
htop

# Utilisation disque
df -h
du -sh /*

# Processus réseau
netstat -tuln
ss -tuln
```

---

## 7. Scripts de sauvegarde

### Script automatisé avec logging
**Fichier :** `scripts/backup/backup_plateforme.sh`

Le script de sauvegarde inclut :
- ✅ Horodatage automatique des archives
- ✅ Journalisation complète des opérations
- ✅ Création automatique des répertoires
- ✅ Gestion des erreurs

```bash
# Exécution du script de sauvegarde
./scripts/backup/backup_plateforme.sh
```

**Fonctionnalités :**
- Compression automatique en `.tar.gz`
- Historique dans `backup_history.log`
- Horodatage format `YYYYMMDD_HHMMSS`

### Programmation automatique
```bash
# Ajouter à crontab pour exécution quotidienne à 2h
crontab -e
# Ajouter : 0 2 * * * /chemin/vers/scripts/backup/backup_plateforme.sh
```

---

## 8. Automatisation système

### Script de mise à jour interactive
**Fichier :** `scripts/system/update_system.sh`
```bash
#!/usr/bin/env bash
# update_system.sh

set -euo pipefail

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
    echo "Ce script doit être exécuté avec sudo"
    exit 1
fi

echo "=== Mise à jour du système Debian ==="

# Mise à jour de la liste des paquets
echo "📦 Mise à jour de la liste des paquets..."
apt update

# Affichage des mises à jour disponibles
echo -e "\n📋 Mises à jour disponibles :"
apt list --upgradable

# Demande de confirmation
echo ""
read -p "Voulez-vous installer ces mises à jour ? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Installation des mises à jour..."
    apt upgrade -y
    echo "✅ Mise à jour terminée avec succès"
else
    echo "❌ Mise à jour annulée"
fi
```

---

## 9. Gestion des dépendances

### Script d'installation serveur web complet
**Fichier :** `scripts/system/install_deps.sh`
```bash
#!/usr/bin/env bash
# install_webserver.sh

set -euo pipefail

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Ce script doit être exécuté avec sudo"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

echo "🚀 Installation d'un serveur web complet"

# Mise à jour système
echo "📦 Mise à jour des paquets..."
apt update
apt install -y apt-transport-https curl gnupg ca-certificates lsb-release

# Installation Apache2
echo "🌐 Installation d'Apache2..."
apt install -y apache2
systemctl enable --now apache2

# Installation MariaDB
echo "🗄️ Installation de MariaDB..."
apt install -y mariadb-server
systemctl enable --now mariadb

# Configuration phpMyAdmin (non-interactive)
echo "🐘 Installation de phpMyAdmin..."
printf "phpmyadmin phpmyadmin/dbconfig-install boolean true
phpmyadmin phpmyadmin/mysql/admin-pass password
phpmyadmin phpmyadmin/mysql/app-pass password
phpmyadmin phpmyadmin/app-password-confirm password
phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

apt install -y phpmyadmin php libapache2-mod-php php-mbstring php-zip php-gd php-curl

# Activation de phpMyAdmin
a2enconf phpmyadmin
systemctl reload apache2

# Installation Node.js (LTS)
echo "⚡ Installation de Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# Installation Git
echo "📋 Installation de Git..."
apt install -y git

# Affichage des informations
IP=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ Installation terminée !"
echo "🌐 Apache : http://${IP}"
echo "🐘 phpMyAdmin : http://${IP}/phpmyadmin"
echo "⚡ Node.js version : $(node --version)"
echo "📋 Git version : $(git --version)"
```

---

## 10. Sécurisation des scripts

### Mesures de sécurité appliquées

#### Mode strict bash
```bash
#!/usr/bin/env bash
set -euo pipefail
# -e : Arrêt sur erreur
# -u : Erreur sur variable non définie  
# -o pipefail : Erreur dans les pipes
```

#### Validation des entrées
```bash
# Validation des paramètres
validate_input() {
    local input="$1"
    # Échapper les caractères dangereux
    if [[ "$input" =~ [';|&$`] ]]; then
        echo "❌ Caractères dangereux détectés" >&2
        exit 1
    fi
}
```

#### Protection des données sensibles
```bash
# Masquage des informations sensibles dans les logs
log_safe() {
    local message="$1"
    # Masquer les clés API/mots de passe
    echo "$message" | sed 's/api_key=[^&]*/api_key=***HIDDEN***/g'
}
```

### Risques identifiés et solutions

| Risque | Impact | Solution appliquée |
|--------|---------|-------------------|
| Injection de commandes | Exécution de code malveillant | Validation stricte des entrées |
| Variables non définies | Comportement imprévisible | `set -u` |
| Erreurs silencieuses | Masquage de problèmes | `set -e` et logging |
| Exposition de secrets | Compromission sécuritaire | Fichiers `.env` et masquage |

---

## 11. API Web sécurisée

### 🌤️ API OpenWeather - Configuration et utilisation

#### Installation et configuration
**Fichiers :** `scripts/api/install.sh` et `scripts/api/openweather_api.sh`

```bash
# Configuration initiale (création du fichier .env)
cd scripts/api
./install.sh

# Utilisation du client API
./openweather_api.sh current              # Ville par défaut
./openweather_api.sh current "Paris"      # Ville spécifique
./openweather_api.sh current "Tokyo" imperial  # Avec unités
./openweather_api.sh config               # Afficher la configuration
./openweather_api.sh help                 # Aide
```

### Fonctionnalités de sécurité implémentées

- ✅ **Clé API sécurisée** : Stockage dans `.env`, masquage dans les logs
- ✅ **Mode strict bash** : `set -euo pipefail`
- ✅ **Validation des entrées** : Regex pour noms de villes
- ✅ **Gestion d'erreurs HTTP** : Codes 200, 401, 404, etc.
- ✅ **Logging sécurisé** : Séparation requêtes/réponses/erreurs
- ✅ **Timeouts** : Protection contre les blocages réseau
- ✅ **Validation JSON** : Vérification intégrité des données

### Structure des logs
```
scripts/api/logs/
├── api_requests.log    # Requêtes avec URLs (clés masquées)
├── api_responses.log   # Réponses HTTP et données JSON
└── errors.log          # Erreurs et avertissements
```

### Script de surveillance système
**Fichier :** `scripts/monitoring/capture_stats.sh`

Capture automatique de métriques système :
- 📊 Utilisation CPU (user, system, idle)
- 💾 Mémoire (libre, utilisée)
- 💽 E/S disque (lecture, écriture)
- 🌐 Trafic réseau (entrant, sortant)

```bash
# Lancement de la surveillance
./scripts/monitoring/capture_stats.sh

# Consultation des données
cat scripts/monitoring/stats.csv
```

---

## 🔧 Outils et dépendances

### Requis système
- **OS :** Debian/Ubuntu Linux
- **Bash :** Version 4.0+
- **Utilitaires :** curl, jq, tar, gzip

### Installation des dépendances
```bash
# Installation automatique
sudo ./scripts/system/install_deps.sh

# Installation manuelle
sudo apt update
sudo apt install -y curl jq apache2 mariadb-server nodejs git
```

---

### Fichiers sensibles à protéger
```bash
# Ajout au .gitignore
scripts/api/.env
scripts/api/logs/*.log
scripts/monitoring/stats.csv
```
