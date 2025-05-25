#!/bin/bash

# =============================================================================
# Script sécurisé pour l'API OpenWeather
# Auteur: GitHub Copilot
# Date: 25 mai 2025
# Description: Script bash avec gestion d'erreurs et logging pour OpenWeather API
# =============================================================================

set -euo pipefail  # Mode strict: arrêt sur erreur, variables non définies, erreurs dans les pipes

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/.env"
readonly LOG_DIR="${SCRIPT_DIR}/logs"
readonly REQUEST_LOG="${LOG_DIR}/api_requests.log"
readonly RESPONSE_LOG="${LOG_DIR}/api_responses.log"
readonly ERROR_LOG="${LOG_DIR}/errors.log"
readonly API_BASE_URL="https://api.openweathermap.org/data/2.5"

# Couleurs pour l'affichage
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Variables globales
API_KEY=""
DEFAULT_CITY="Paris"
DEFAULT_UNITS="metric"

# =============================================================================
# Fonctions utilitaires
# =============================================================================

# Fonction de logging avec timestamp
log_message() {
    local level="$1"
    local message="$2"
    local logfile="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$logfile"
}

# Fonction d'affichage coloré
print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Fonction d'erreur avec logging
error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    
    print_colored "$RED" "ERREUR: $message"
    log_message "ERROR" "$message" "$ERROR_LOG"
    exit "$exit_code"
}

# Fonction d'avertissement
warning() {
    local message="$1"
    print_colored "$YELLOW" "ATTENTION: $message"
    log_message "WARNING" "$message" "$ERROR_LOG"
}

# Fonction d'information
info() {
    local message="$1"
    print_colored "$BLUE" "INFO: $message"
}

# Fonction de succès
success() {
    local message="$1"
    print_colored "$GREEN" "SUCCÈS: $message"
}

# =============================================================================
# Fonctions de configuration et initialisation
# =============================================================================

# Création des répertoires nécessaires
create_directories() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" || error_exit "Impossible de créer le répertoire de logs: $LOG_DIR"
        info "Répertoire de logs créé: $LOG_DIR"
    fi
}

# Chargement de la configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Lecture sécurisée du fichier de configuration
        while IFS='=' read -r key value; do
            # Ignorer les commentaires et lignes vides
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Nettoyer la valeur (enlever les guillemets)
            value=$(echo "$value" | sed 's/^["'\'']//' | sed 's/["'\'']$//')
            
            case "$key" in
                "API_KEY") API_KEY="$value" ;;
                "DEFAULT_CITY") DEFAULT_CITY="$value" ;;
                "DEFAULT_UNITS") DEFAULT_UNITS="$value" ;;
            esac
        done < "$CONFIG_FILE"
    else
        warning "Fichier de configuration non trouvé: $CONFIG_FILE"
        create_config_template
    fi
    
    # Vérification de la clé API
    if [[ -z "$API_KEY" ]]; then
        error_exit "Clé API manquante. Veuillez configurer votre clé API dans $CONFIG_FILE"
    fi
}

# Création d'un template de configuration
create_config_template() {
    cat > "$CONFIG_FILE" << 'EOF'
# Configuration pour l'API OpenWeather
# Obtenez votre clé API sur: https://openweathermap.org/api

# Votre clé API OpenWeather (OBLIGATOIRE)
API_KEY=your_api_key_here

# Ville par défaut
DEFAULT_CITY=Paris

# Unités par défaut (metric, imperial, kelvin)
DEFAULT_UNITS=metric
EOF

    info "Template de configuration créé: $CONFIG_FILE"
    info "Veuillez éditer ce fichier avec votre clé API avant de continuer"
}

# =============================================================================
# Fonctions de validation
# =============================================================================

# Validation de la clé API
validate_api_key() {
    if [[ ${#API_KEY} -lt 32 ]]; then
        error_exit "Clé API invalide (trop courte). Vérifiez votre configuration."
    fi
    
    if [[ ! "$API_KEY" =~ ^[a-zA-Z0-9]+$ ]]; then
        error_exit "Clé API invalide (caractères non autorisés). Vérifiez votre configuration."
    fi
}

# Validation des paramètres de ville
validate_city() {
    local city="$1"
    
    if [[ -z "$city" ]]; then
        error_exit "Nom de ville vide"
    fi
    
    if [[ ${#city} -lt 2 ]]; then
        error_exit "Nom de ville trop court"
    fi
    
    # Vérification des caractères dangereux
    if [[ "$city" =~ [\"\'\\$\`] ]]; then
        error_exit "Caractères dangereux détectés dans le nom de ville"
    fi
}

# Validation des unités
validate_units() {
    local units="$1"
    
    case "$units" in
        "metric"|"imperial"|"kelvin")
            return 0
            ;;
        *)
            error_exit "Unités invalides: $units. Utilisez: metric, imperial, ou kelvin"
            ;;
    esac
}

# =============================================================================
# Fonctions API
# =============================================================================

# Fonction générique pour les requêtes API
make_api_request() {
    local endpoint="$1"
    local params="$2"
    local description="$3"
    
    local url="${API_BASE_URL}${endpoint}?${params}&appid=${API_KEY}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log de la requête (sans la clé API pour la sécurité)
    local safe_url=$(echo "$url" | sed "s/appid=[^&]*/appid=***HIDDEN***/")
    log_message "REQUEST" "$description - URL: $safe_url" "$REQUEST_LOG"
    
    info "Requête: $description"
    
    # Exécution de la requête avec gestion d'erreur
    local response
    local http_code
    
    if ! response=$(curl -s -w "%{http_code}" --max-time 30 --retry 3 --retry-delay 2 "$url" 2>/dev/null); then
        error_exit "Échec de la connexion à l'API OpenWeather"
    fi
    
    # Extraction du code HTTP et du contenu
    http_code="${response: -3}"
    response="${response%???}"
    
    # Log de la réponse
    log_message "RESPONSE" "$description - HTTP: $http_code - Data: $response" "$RESPONSE_LOG"
    
    # Gestion des codes d'erreur HTTP
    case "$http_code" in
        200)
            success "Requête réussie (HTTP 200)"
            ;;
        401)
            error_exit "Clé API invalide ou manquante (HTTP 401)"
            ;;
        404)
            error_exit "Ville non trouvée (HTTP 404)"
            ;;
        429)
            error_exit "Limite de requêtes atteinte (HTTP 429)"
            ;;
        5*)
            error_exit "Erreur serveur OpenWeather (HTTP $http_code)"
            ;;
        *)
            error_exit "Erreur inattendue (HTTP $http_code)"
            ;;
    esac
    
    # Vérification que la réponse est du JSON valide
    if ! echo "$response" | jq . >/dev/null 2>&1; then
        error_exit "Réponse API invalide (pas du JSON valide)"
    fi
    
    echo "$response"
}

# Obtenir les données météo actuelles
get_current_weather() {
    local city="${1:-$DEFAULT_CITY}"
    local units="${2:-$DEFAULT_UNITS}"
    
    validate_city "$city"
    validate_units "$units"
    
    local params="q=$(printf '%s' "$city" | jq -rR @uri)&units=$units&lang=fr"
    local response
    
    response=$(make_api_request "/weather" "$params" "Météo actuelle pour $city")
    
    # Parsing et affichage des données
    parse_current_weather "$response"
}

# Obtenir les prévisions météo
get_forecast() {
    local city="${1:-$DEFAULT_CITY}"
    local units="${2:-$DEFAULT_UNITS}"
    local days="${3:-5}"
    
    validate_city "$city"
    validate_units "$units"
    
    if ! [[ "$days" =~ ^[1-5]$ ]]; then
        error_exit "Nombre de jours invalide: $days (1-5 autorisés)"
    fi
    
    local params="q=$(printf '%s' "$city" | jq -rR @uri)&units=$units&lang=fr&cnt=$((days * 8))"
    local response
    
    response=$(make_api_request "/forecast" "$params" "Prévisions pour $city ($days jours)")
    
    # Parsing et affichage des données
    parse_forecast "$response" "$days"
}

# =============================================================================
# Fonctions de parsing et affichage
# =============================================================================

# Parser les données météo actuelles
parse_current_weather() {
    local json="$1"
    
    echo
    echo "============================================="
    echo "         MÉTÉO ACTUELLE"
    echo "============================================="
    
    # Extraction des données avec jq et gestion d'erreur
    local city temp feels_like humidity pressure description wind_speed visibility
    
    city=$(echo "$json" | jq -r '.name // "N/A"')
    temp=$(echo "$json" | jq -r '.main.temp // "N/A"')
    feels_like=$(echo "$json" | jq -r '.main.feels_like // "N/A"')
    humidity=$(echo "$json" | jq -r '.main.humidity // "N/A"')
    pressure=$(echo "$json" | jq -r '.main.pressure // "N/A"')
    description=$(echo "$json" | jq -r '.weather[0].description // "N/A"')
    wind_speed=$(echo "$json" | jq -r '.wind.speed // "N/A"')
    visibility=$(echo "$json" | jq -r '.visibility // "N/A"')
    
    printf "%-20s: %s\n" "Ville" "$city"
    printf "%-20s: %s°C\n" "Température" "$temp"
    printf "%-20s: %s°C\n" "Ressenti" "$feels_like"
    printf "%-20s: %s\n" "Description" "$description"
    printf "%-20s: %s%%\n" "Humidité" "$humidity"
    printf "%-20s: %s hPa\n" "Pression" "$pressure"
    printf "%-20s: %s m/s\n" "Vent" "$wind_speed"
    printf "%-20s: %s m\n" "Visibilité" "$visibility"
    
    echo "============================================="
    echo
}

# Parser les prévisions météo
parse_forecast() {
    local json="$1"
    local days="$2"
    
    echo
    echo "============================================="
    echo "         PRÉVISIONS MÉTÉO ($days JOURS)"
    echo "============================================="
    
    local city
    city=$(echo "$json" | jq -r '.city.name // "N/A"')
    echo "Ville: $city"
    echo
    
    # Extraction des prévisions par tranche de 24h
    local i=0
    while [[ $i -lt $((days * 8)) ]]; do
        local date temp_min temp_max description
        
        date=$(echo "$json" | jq -r ".list[$i].dt_txt // \"N/A\"")
        temp_min=$(echo "$json" | jq -r ".list[$i].main.temp_min // \"N/A\"")
        temp_max=$(echo "$json" | jq -r ".list[$i].main.temp_max // \"N/A\"")
        description=$(echo "$json" | jq -r ".list[$i].weather[0].description // \"N/A\"")
        
        if [[ "$date" != "N/A" ]]; then
            printf "%s | %s°C - %s°C | %s\n" \
                "$(date -d "$date" '+%d/%m %H:%M' 2>/dev/null || echo "$date")" \
                "$temp_min" "$temp_max" "$description"
        fi
        
        ((i += 8)) # Saut de 24h (8 créneaux de 3h)
    done
    
    echo "============================================="
    echo
}

# =============================================================================
# Fonctions d'aide et menu
# =============================================================================

# Affichage de l'aide
show_help() {
    cat << 'EOF'
=============================================================================
                    SCRIPT API OPENWEATHER
=============================================================================

UTILISATION:
    ./openweather_api.sh [COMMANDE] [OPTIONS]

COMMANDES:
    current [ville] [unités]    - Météo actuelle
    forecast [ville] [unités] [jours] - Prévisions météo
    help                        - Afficher cette aide
    config                      - Vérifier la configuration

OPTIONS:
    ville     : Nom de la ville (défaut: Paris)
    unités    : metric/imperial/kelvin (défaut: metric)
    jours     : Nombre de jours pour les prévisions (1-5, défaut: 5)

EXEMPLES:
    ./openweather_api.sh current
    ./openweather_api.sh current "New York" imperial
    ./openweather_api.sh forecast Lyon metric 3
    ./openweather_api.sh forecast Tokyo

CONFIGURATION:
    Éditez le fichier .env avec votre clé API OpenWeather
    
LOGS:
    - Requêtes: logs/api_requests.log
    - Réponses: logs/api_responses.log
    - Erreurs: logs/errors.log

=============================================================================
EOF
}

# Vérification de la configuration
check_config() {
    echo "============================================="
    echo "         VÉRIFICATION DE LA CONFIGURATION"
    echo "============================================="
    
    echo "Fichier de configuration: $CONFIG_FILE"
    if [[ -f "$CONFIG_FILE" ]]; then
        success "✓ Fichier trouvé"
    else
        error_exit "✗ Fichier non trouvé"
    fi
    
    echo "Clé API: ${API_KEY:0:8}..."
    if [[ -n "$API_KEY" && ${#API_KEY} -ge 32 ]]; then
        success "✓ Clé API configurée"
    else
        error_exit "✗ Clé API manquante ou invalide"
    fi
    
    echo "Ville par défaut: $DEFAULT_CITY"
    echo "Unités par défaut: $DEFAULT_UNITS"
    
    echo "Répertoire de logs: $LOG_DIR"
    if [[ -d "$LOG_DIR" ]]; then
        success "✓ Répertoire de logs présent"
    else
        warning "✗ Répertoire de logs manquant"
    fi
    
    echo "Test de connectivité..."
    if ping -c 1 api.openweathermap.org >/dev/null 2>&1; then
        success "✓ Connectivité OK"
    else
        warning "✗ Problème de connectivité"
    fi
    
    echo "============================================="
}

# =============================================================================
# Fonction principale
# =============================================================================

main() {
    # Initialisation
    create_directories
    load_config
    validate_api_key
    
    # Gestion des arguments
    case "${1:-help}" in
        "current")
            get_current_weather "${2:-}" "${3:-}"
            ;;
        "forecast")
            get_forecast "${2:-}" "${3:-}" "${4:-}"
            ;;
        "config")
            check_config
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            warning "Commande inconnue: $1"
            show_help
            exit 1
            ;;
    esac
}

# =============================================================================
# Point d'entrée
# =============================================================================

# Vérification des dépendances
command -v curl >/dev/null 2>&1 || error_exit "curl n'est pas installé"
command -v jq >/dev/null 2>&1 || error_exit "jq n'est pas installé"

# Gestion des signaux pour un arrêt propre
trap 'error_exit "Script interrompu par l'\''utilisateur"' INT TERM

# Exécution du script
main "$@"
