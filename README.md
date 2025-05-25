# Système, Scripts et Sécurité

Projet complet d'administration système et de sécurisation de scripts bash avec exploitation d'API, surveillance système et automatisation des tâches.

## 📋 Sommaire du projet

1. [Création d'une VM Debian](#1-création-dune-vm-debian)
2. [Commandes de recherche avancée](#2-commandes-de-recherche-avancée)
3. [Compression et décompression](#3-compression-et-décompression)
4. [Manipulation de texte](#4-manipulation-de-texte)
5. [Gestion des processus](#5-gestion-des-processus)
6. [Surveillance des ressources](#6-surveillance-des-ressources)
7. [Scripting avancé](#7-scripting-avancé)
8. [Automatisation des mises à jour](#8-automatisation-des-mises-à-jour)
9. [Gestion des dépendances](#9-gestion-des-dépendances)
10. [Sécurisation des scripts](#10-sécurisation-des-scripts)
11. [Utilisation d'API Web](#11-utilisation-dapi-web)

---

## 1. Création d'une VM Debian

### Configuration initiale
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

## 3. Compression et décompression

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
# monitor_system.sh

# En-tête CSV
echo "Timestamp,CPU User,CPU System,CPU Idle,Memory Free,Memory Used,Disk Read,Disk Write,Network In,Network Out" > stats.csv

# Capture des données (5 iterations)
for i in {1..5}; do
    # Statistiques système
    vmstat_output=$(vmstat 1 1)
    cpu_user=$(echo "$vmstat_output" | awk 'NR==3 {print $13}')
    cpu_system=$(echo "$vmstat_output" | awk 'NR==3 {print $14}')
    cpu_idle=$(echo "$vmstat_output" | awk 'NR==3 {print $15}')
    memory_free=$(echo "$vmstat_output" | awk 'NR==3 {print $4}')
    memory_used=$(echo "$vmstat_output" | awk 'NR==3 {print $3}')

    # Statistiques disque
    iostat_output=$(iostat -d 1 1)
    disk_read=$(echo "$iostat_output" | awk 'NR==4 {print $3}')
    disk_write=$(echo "$iostat_output" | awk 'NR==4 {print $4}')

    # Statistiques réseau
    netstat_output=$(netstat -i)
    network_in=$(echo "$netstat_output" | awk 'NR==4 {print $4}')
    network_out=$(echo "$netstat_output" | awk 'NR==4 {print $8}')

    # Écriture dans le CSV
    echo "$(date),$cpu_user,$cpu_system,$cpu_idle,$memory_free,$memory_used,$disk_read,$disk_write,$network_in,$network_out" >> stats.csv
    
    sleep 1
done
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

## 7. Scripting avancé

### Script de sauvegarde automatique
```bash
#!/usr/bin/env bash
# backup_plateforme.sh

set -euo pipefail

# Configuration
SRC="/home/La_Plateforme/Documents/Plateforme"
DEST_BASE="/home/La_Plateforme/Backups/Plateforme"
LOG_FILE="${DEST_BASE}/backup_history.log"

# Création du répertoire de destination
mkdir -p "${DEST_BASE}"

# Génération du timestamp
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
ARCHIVE="${DEST_BASE}/Plateforme_${TIMESTAMP}.tar.gz"

# Logging du début
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Début sauvegarde : ${SRC} -> ${ARCHIVE}" | tee -a "${LOG_FILE}"

# Création de l'archive
tar -czf "${ARCHIVE}" -C "$(dirname "${SRC}")" "$(basename "${SRC}")"
EXIT_CODE=$?

# Logging du résultat
if [ ${EXIT_CODE} -eq 0 ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Sauvegarde réussie : ${ARCHIVE}" | tee -a "${LOG_FILE}"
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Échec sauvegarde (code ${EXIT_CODE})" | tee -a "${LOG_FILE}" >&2
    exit ${EXIT_CODE}
fi
```

### Automatisation avec cron
```bash
# Ajouter à crontab pour exécution quotidienne à 2h
crontab -e
# Ajouter : 0 2 * * * /home/La_Plateforme/backup_plateforme.sh
```

---

## 8. Automatisation des mises à jour

### Script de mise à jour interactive
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

## 11. Utilisation d'API Web

### Script OpenWeather sécurisé

#### Configuration et installation
```bash
# install.sh
#!/usr/bin/env bash
set -euo pipefail

echo "🌤️ Configuration de l'API OpenWeather"

# Création du fichier .env s'il n'existe pas
if [[ ! -f .env ]]; then
    read -p "Entrez votre clé API OpenWeather : " -s api_key
    echo
    
    cat > .env << EOF
API_KEY=${api_key}
DEFAULT_CITY=Paris
DEFAULT_UNITS=metric
EOF
    
    echo "✅ Configuration sauvegardée dans .env"
else
    echo "ℹ️ Fichier .env existant trouvé"
fi

# Création du répertoire de logs
mkdir -p logs
echo "📁 Répertoire de logs créé"
```

#### Script principal API
```bash
#!/usr/bin/env bash
# openweather_api.sh

set -euo pipefail

# Configuration
CONFIG_FILE=".env"
LOG_DIR="logs"

# Chargement de la configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "❌ Fichier .env manquant. Exécutez ./install.sh" >&2
    exit 1
fi

# Validation de la clé API
if [[ -z "${API_KEY:-}" ]]; then
    echo "❌ Clé API manquante dans .env" >&2
    exit 1
fi

# Fonction de logging sécurisé
log_request() {
    local url="$1"
    local safe_url=$(echo "$url" | sed "s/appid=[^&]*/appid=***HIDDEN***/g")
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [REQUEST] $safe_url" >> "$LOG_DIR/api_requests.log"
}

log_response() {
    local status="$1"
    local data="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [RESPONSE] HTTP: $status - Data: $data" >> "$LOG_DIR/api_responses.log"
}

log_error() {
    local error="$1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $error" >> "$LOG_DIR/errors.log"
}

# Fonction principale
get_weather() {
    local city="${1:-$DEFAULT_CITY}"
    local units="${2:-$DEFAULT_UNITS}"
    
    # Validation de l'entrée
    if [[ ! "$city" =~ ^[a-zA-Z\ \-,]+$ ]]; then
        log_error "Nom de ville invalide: $city"
        echo "❌ Nom de ville invalide" >&2
        return 1
    fi
    
    # Construction de l'URL
    local url="https://api.openweathermap.org/data/2.5/weather?q=${city}&units=${units}&lang=fr&appid=${API_KEY}"
    
    # Logging de la requête
    log_request "$url"
    
    # Appel API avec gestion d'erreurs
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" --max-time 10 "$url" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    local json_data=$(echo "$response" | head -n -1)
    
    # Validation de la réponse HTTP
    case "$http_code" in
        200)
            # Validation JSON
            if ! echo "$json_data" | jq . >/dev/null 2>&1; then
                log_error "Réponse JSON invalide"
                echo "❌ Erreur de format de données" >&2
                return 1
            fi
            
            log_response "$http_code" "$json_data"
            
            # Extraction et affichage des données
            local temp=$(echo "$json_data" | jq -r '.main.temp')
            local description=$(echo "$json_data" | jq -r '.weather[0].description')
            local humidity=$(echo "$json_data" | jq -r '.main.humidity')
            
            echo "🌤️ Météo pour $city"
            echo "🌡️ Température: ${temp}°C"
            echo "☁️ Conditions: $description"
            echo "💧 Humidité: ${humidity}%"
            ;;
        401)
            log_error "Clé API invalide (HTTP 401)"
            echo "❌ Clé API invalide" >&2
            return 1
            ;;
        404)
            log_error "Ville non trouvée: $city (HTTP 404)"
            echo "❌ Ville '$city' non trouvée" >&2
            return 1
            ;;
        *)
            log_error "Erreur API (HTTP $http_code)"
            echo "❌ Erreur API (Code: $http_code)" >&2
            return 1
            ;;
    esac
}

# Interface utilisateur
case "${1:-current}" in
    "current")
        get_weather "${2:-}" "${3:-}"
        ;;
    "config")
        echo "📋 Configuration actuelle:"
        echo "Ville par défaut: ${DEFAULT_CITY}"
        echo "Unités: ${DEFAULT_UNITS}"
        echo "Logs: $LOG_DIR/"
        ;;
    "help")
        echo "Usage: $0 [current|config|help] [ville] [unités]"
        echo "Exemples:"
        echo "  $0 current"
        echo "  $0 current 'New York'"
        echo "  $0 current 'Tokyo' imperial"
        ;;
    *)
        echo "❌ Commande inconnue. Utilisez '$0 help'" >&2
        exit 1
        ;;
esac
```

### Fonctionnalités de sécurité implémentées

- ✅ **Clé API sécurisée** : Stockage dans `.env`, masquage dans les logs
- ✅ **Validation stricte** : Vérification des entrées utilisateur
- ✅ **Gestion d'erreurs HTTP** : Codes 200, 401, 404, etc.
- ✅ **Logging complet** : Requêtes, réponses et erreurs séparées
- ✅ **Timeouts** : Protection contre les blocages
- ✅ **Validation JSON** : Vérification de l'intégrité des données

### Structure des logs

```
logs/
├── api_requests.log    # Requêtes avec URLs (clés masquées)
├── api_responses.log   # Réponses HTTP et données JSON
└── errors.log          # Erreurs et avertissements
```