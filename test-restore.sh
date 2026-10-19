#!/bin/bash
# Simula un desastre (borra Nextcloud y su BD) y restaura el último backup.
set -euo pipefail
source /etc/nextcloud-lab.conf
[ "$EUID" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
echo "ATENCIÓN: borrará $NC_DIR, $DATA_DIR y la BD '$DB_NAME', y restaurará el último backup."
read -rp "Escribe SI para continuar: " R
[ "$R" = "SI" ] || { echo "Cancelado"; exit 1; }
/usr/local/bin/backup-nextcloud.sh
rm -rf "$NC_DIR" "$DATA_DIR"
mysql -e "DROP DATABASE \`$DB_NAME\`;"
echo "Desastre simulado. Comprueba que el sitio está roto y pulsa Enter para restaurar."
read -r
/usr/local/bin/restore-nextcloud.sh
echo "Comprueba en el navegador que usuarios y archivos han vuelto."
