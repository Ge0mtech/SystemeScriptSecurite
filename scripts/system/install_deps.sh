#!/usr/bin/env bash
set -e

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être exécuté en tant que root. Utilisez sudo ou connectez-vous en root."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Mise à jour des sources et paquets utilitaires
apt update
apt install -y apt-transport-https curl gnupg ca-certificates lsb-release

# Installation et démarrage d’Apache2 (nécessaire pour phpMyAdmin)
apt install -y apache2
systemctl enable --now apache2

# Installation de MariaDB
apt install -y mariadb-server
systemctl enable --now mariadb

# Configuration non interactive et installation de phpMyAdmin
printf "phpmyadmin phpmyadmin/dbconfig-install boolean true
phpmyadmin phpmyadmin/mysql/admin-pass password
phpmyadmin phpmyadmin/mysql/app-pass password
phpmyadmin phpmyadmin/app-password-confirm password
phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" \
  | debconf-set-selections
apt install -y phpmyadmin

# Installer les paquets PHP requis et activer phpMyAdmin dans Apache
apt install -y php libapache2-mod-php php-mbstring php-zip php-gd php-curl
a2enconf phpmyadmin
systemctl reload apache2

# Installation de Node.js (LTS) et npm via NodeSource
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# Installation de Git
apt install -y git

# Affichage de l’URL de phpMyAdmin
IP=$(hostname -I | awk '{print $1}')
echo
echo "phpMyAdmin est disponible sur : http://${IP}/phpmyadmin"
echo

# Ouverture automatique si xdg-open est installé
if command -v xdg-open &> /dev/null; then
  xdg-open "http://${IP}/phpmyadmin"
fi

echo "Installation des dépendances terminée avec succès !"