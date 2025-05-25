#!/usr/bin/env bash
# Script pour Debian : recherche de mises à jour et mise à jour interactive

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root. Utilisez sudo."
  exit 1
fi

# Mise à jour de la liste des paquets
echo "Mise à jour de la liste des paquets..."
apt update

# Affichage des paquets pouvant être mis à jour
echo -e "\nMises à jour disponibles :"
apt list --upgradable

echo
read -p "Voulez-vous mettre à jour ces paquets ? [y/N] " reponse

case "$reponse" in
  [yY])
    echo "Lancement de la mise à jour..."
    apt upgrade -y
    echo "Mise à jour terminée avec succès."
    ;;
  *)
    echo "Mise à jour annulée."
    ;;
esac
