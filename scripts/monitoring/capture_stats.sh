#!/bin/bash

# En-tête du fichier CSV
echo "Timestamp,CPU User,CPU System,CPU Idle,Memory Free,Memory Used,Disk Read,Disk Write,Network In,Network Out" > stats.csv

# Boucle pour capturer les données
for i in {1..5}; do
    # Obtenir les statistiques CPU et mémoire
    vmstat_output=$(vmstat 1 1)
    cpu_user=$(echo "$vmstat_output" | awk 'NR==3 {print $13}')
    cpu_system=$(echo "$vmstat_output" | awk 'NR==3 {print $14}')
    cpu_idle=$(echo "$vmstat_output" | awk 'NR==3 {print $15}')
    memory_free=$(echo "$vmstat_output" | awk 'NR==3 {print $4}')
    memory_used=$(echo "$vmstat_output" | awk 'NR==3 {print $3}')

    # Obtenir les statistiques de disque
    iostat_output=$(iostat -d 1 1)
    disk_read=$(echo "$iostat_output" | awk 'NR==4 {print $3}')
    disk_write=$(echo "$iostat_output" | awk 'NR==4 {print $4}')

    # Obtenir les statistiques réseau
    netstat_output=$(netstat -i)
    network_in=$(echo "$netstat_output" | awk 'NR==4 {print $4}')
    network_out=$(echo "$netstat_output" | awk 'NR==4 {print $8}')

    # Écrire dans le fichier CSV
    echo "$(date),$cpu_user,$cpu_system,$cpu_idle,$memory_free,$memory_used,$disk_read,$disk_write,$network_in,$network_out" >> stats.csv

    # Attendre avant la prochaine capture
    sleep 1
done

