#!/usr/bin/env bash
# Script de sauvegarde périodique avec historique

# Répertoire source à sauvegarder
SRC="/home/develop/Documents/Plateforme"
# Répertoire de destination pour les archives et le journal
DEST_BASE="/home/develop/Backups/Plateforme"
# Fichier de log pour l'historique des sauvegardes
LOG_FILE="${DEST_BASE}/backup_history.log"

# Création du dossier de destination s'il n'existe pas
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Vérification du dossier de destination : ${DEST_BASE}"
mkdir -p "${DEST_BASE}"

# Génération d'un timestamp pour nommer l'archive
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
ARCHIVE="${DEST_BASE}/Plateforme_${TIMESTAMP}.tar.gz"

# Début de la sauvegarde avec journalisation
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Début de la sauvegarde : ${SRC} -> ${ARCHIVE}" | tee -a "${LOG_FILE}"

tar -czf "${ARCHIVE}" -C "$(dirname "${SRC}")" "$(basename "${SRC}")"
EXIT_CODE=$?

# Enregistrement du résultat de la sauvegarde
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Résultat (code $EXIT_CODE) pour ${ARCHIVE}" | tee -a "${LOG_FILE}"

if [ ${EXIT_CODE} -ne 0 ]; then
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Échec de la sauvegarde : ${ARCHIVE}" | tee -a "${LOG_FILE}" >&2
  exit ${EXIT_CODE}
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Sauvegarde terminée avec succès." | tee -a "${LOG_FILE}"
