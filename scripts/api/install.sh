#!/bin/bash

# =============================================================================
# Script d'installation pour l'API OpenWeather
# =============================================================================

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo
    print_colored "$BLUE" "============================================="
    print_colored "$BLUE" "    INSTALLATION SCRIPT API OPENWEATHER"
    print_colored "$BLUE" "============================================="
    echo
}

check_dependencies() {
    print_colored "$YELLOW" "🔍 Vérification des dépendances..."
    
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_colored "$RED" "❌ Dépendances manquantes: ${missing_deps[*]}"
        echo
        
        if command -v apt >/dev/null 2>&1; then
            print_colored "$YELLOW" "Installation automatique (Ubuntu/Debian):"
            echo "sudo apt update && sudo apt install ${missing_deps[*]}"
            
            read -p "Voulez-vous installer automatiquement? (o/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[OoYy]$ ]]; then
                sudo apt update && sudo apt install "${missing_deps[@]}"
            else
                print_colored "$RED" "Veuillez installer manuellement: ${missing_deps[*]}"
                exit 1
            fi
        elif command -v yum >/dev/null 2>&1; then
            print_colored "$YELLOW" "Installation manuelle requise (CentOS/RHEL):"
            echo "sudo yum install ${missing_deps[*]}"
            exit 1
        else
            print_colored "$RED" "Gestionnaire de paquets non supporté"
            print_colored "$YELLOW" "Veuillez installer manuellement: ${missing_deps[*]}"
            exit 1
        fi
    else
        print_colored "$GREEN" "✅ Toutes les dépendances sont installées"
    fi
}

setup_permissions() {
    print_colored "$YELLOW" "🔐 Configuration des permissions..."
    
    if [[ -f "openweather_api.sh" ]]; then
        chmod +x openweather_api.sh
        print_colored "$GREEN" "✅ Script principal rendu exécutable"
    else
        print_colored "$RED" "❌ Script principal non trouvé"
        exit 1
    fi
}

setup_config() {
    print_colored "$YELLOW" "⚙️ Configuration de l'API..."
    
    if [[ ! -f ".env" ]]; then
        print_colored "$RED" "❌ Fichier .env non trouvé"
        exit 1
    fi
    
    # Vérifier si la clé API est configurée
    if grep -q "your_api_key_here" .env; then
        print_colored "$YELLOW" "🔑 Configuration de la clé API requise"
        echo
        print_colored "$BLUE" "Pour obtenir votre clé API:"
        echo "1. Visitez: https://openweathermap.org/api"
        echo "2. Créez un compte gratuit"
        echo "3. Obtenez votre clé API"
        echo
        
        read -p "Avez-vous votre clé API? (o/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[OoYy]$ ]]; then
            echo
            read -p "Entrez votre clé API: " api_key
            
            if [[ -n "$api_key" && ${#api_key} -ge 32 ]]; then
                sed -i "s/your_api_key_here/$api_key/" .env
                print_colored "$GREEN" "✅ Clé API configurée avec succès"
            else
                print_colored "$RED" "❌ Clé API invalide (trop courte)"
                print_colored "$YELLOW" "Vous pouvez configurer la clé API plus tard en éditant le fichier .env"
            fi
        else
            print_colored "$YELLOW" "Vous pouvez configurer la clé API plus tard en éditant le fichier .env"
        fi
    else
        print_colored "$GREEN" "✅ Clé API déjà configurée"
    fi
}

update_api_key() {
    print_colored "$YELLOW" "🔑 Mise à jour de la clé API..."
    
    if [[ ! -f ".env" ]]; then
        print_colored "$RED" "❌ Fichier .env non trouvé"
        exit 1
    fi
    
    # Afficher la clé API actuelle (masquée)
    local current_key=$(grep "^API_KEY=" .env | cut -d'=' -f2)
    if [[ -n "$current_key" && "$current_key" != "your_api_key_here" ]]; then
        local masked_key="${current_key:0:8}...${current_key: -4}"
        print_colored "$BLUE" "Clé API actuelle: $masked_key"
    else
        print_colored "$YELLOW" "Aucune clé API configurée"
    fi
    
    echo
    print_colored "$BLUE" "Pour obtenir une nouvelle clé API:"
    echo "1. Visitez: https://openweathermap.org/api"
    echo "2. Connectez-vous à votre compte"
    echo "3. Générez une nouvelle clé API"
    echo
    
    read -p "Entrez votre nouvelle clé API: " new_api_key
    
    if [[ -z "$new_api_key" ]]; then
        print_colored "$RED" "❌ Clé API vide"
        exit 1
    fi
    
    if [[ ${#new_api_key} -lt 32 ]]; then
        print_colored "$RED" "❌ Clé API invalide (trop courte)"
        exit 1
    fi
    
    if [[ ! "$new_api_key" =~ ^[a-zA-Z0-9]+$ ]]; then
        print_colored "$RED" "❌ Clé API invalide (caractères non autorisés)"
        exit 1
    fi
    
    # Sauvegarder l'ancienne clé
    if [[ -n "$current_key" && "$current_key" != "your_api_key_here" ]]; then
        echo "# Ancienne clé API sauvegardée le $(date '+%Y-%m-%d %H:%M:%S')" >> .env.backup
        echo "# API_KEY_OLD=$current_key" >> .env.backup
        print_colored "$BLUE" "Ancienne clé sauvegardée dans .env.backup"
    fi
    
    # Mettre à jour la clé API
    if grep -q "^API_KEY=" .env; then
        sed -i "s/^API_KEY=.*/API_KEY=$new_api_key/" .env
    else
        echo "API_KEY=$new_api_key" >> .env
    fi
    
    print_colored "$GREEN" "✅ Clé API mise à jour avec succès"
    
    # Test de la nouvelle clé
    print_colored "$YELLOW" "🧪 Test de la nouvelle clé API..."
    if ./openweather_api.sh config >/dev/null 2>&1; then
        print_colored "$GREEN" "✅ Nouvelle clé API valide"
    else
        print_colored "$RED" "❌ Erreur avec la nouvelle clé API"
        print_colored "$YELLOW" "Vérifiez que la clé est correcte et active"
    fi
}

create_logs_directory() {
    print_colored "$YELLOW" "📁 Création du répertoire de logs..."
    
    if [[ ! -d "logs" ]]; then
        mkdir -p logs
        print_colored "$GREEN" "✅ Répertoire logs créé"
    else
        print_colored "$GREEN" "✅ Répertoire logs existe déjà"
    fi
}

test_installation() {
    print_colored "$YELLOW" "🧪 Test de l'installation..."
    
    if ./openweather_api.sh help >/dev/null 2>&1; then
        print_colored "$GREEN" "✅ Script fonctionnel"
    else
        print_colored "$RED" "❌ Erreur lors du test du script"
        exit 1
    fi
    
    if ./openweather_api.sh config >/dev/null 2>&1; then
        print_colored "$GREEN" "✅ Configuration valide"
    else
        print_colored "$YELLOW" "⚠️ Configuration incomplète (clé API manquante?)"
    fi
}

show_usage_examples() {
    print_colored "$BLUE" "📖 Exemples d'utilisation:"
    echo
    echo "# Météo actuelle"
    echo "./openweather_api.sh current"
    echo "./openweather_api.sh current \"New York\""
    echo
    echo "# Prévisions météo"
    echo "./openweather_api.sh forecast"
    echo "./openweather_api.sh forecast \"Paris\" metric 3"
    echo
    echo "# Aide et configuration"
    echo "./openweather_api.sh help"
    echo "./openweather_api.sh config"
    echo
    echo "# Mise à jour de la clé API"
    echo "./install.sh --update-api-key"
    echo
}

show_help() {
    print_colored "$BLUE" "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --update-api-key    Mettre à jour la clé API OpenWeather"
    echo "  --help, -h          Afficher cette aide"
    echo
    echo "Sans option, lance l'installation complète."
    echo
}

main() {
    # Gestion des arguments
    case "${1:-}" in
        "--update-api-key")
            print_header
            update_api_key
            print_colored "$GREEN" "🎉 Clé API mise à jour!"
            echo
            show_usage_examples
            ;;
        "--help"|"-h")
            show_help
            ;;
        "")
            # Installation complète (comportement par défaut)
            print_header
            
            check_dependencies
            setup_permissions
            create_logs_directory
            setup_config
            test_installation
            
            echo
            print_colored "$GREEN" "🎉 Installation terminée avec succès!"
            echo
            
            show_usage_examples
            
            print_colored "$BLUE" "============================================="
            print_colored "$GREEN" "Prêt à utiliser l'API OpenWeather!"
            print_colored "$BLUE" "============================================="
            ;;
        *)
            print_colored "$RED" "❌ Option inconnue: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Vérification que nous sommes dans le bon répertoire
if [[ ! -f "openweather_api.sh" ]]; then
    print_colored "$RED" "❌ Erreur: Script principal non trouvé"
    print_colored "$YELLOW" "Assurez-vous d'exécuter ce script depuis le répertoire contenant openweather_api.sh"
    exit 1
fi

main "$@"
