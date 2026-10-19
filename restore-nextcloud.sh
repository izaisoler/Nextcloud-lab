#!/bin/bash
# Uso: sudo restore-nextcloud.sh [FECHA]   (por defecto, el último backup)
set -euo pipefail
source /etc/nextcloud-lab.conf
[ "$EUID" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
occ() { (cd "$NC_DIR" && runuser -u www-data -- php occ "$@"); }

FECHA="${1:-}"
if [ -z "$FECHA" ]; then
  DB=$(ls -1t "$BACKUP_DIR"/db_*.sql 2>/dev/null | head -1 || true)
  [ -n "$DB" ] || { echo "No hay backups en $BACKUP_DIR"; exit 1; }
  FECHA="${DB##*/db_}"; FECHA="${FECHA%.sql}"
fi
DBF="$BACKUP_DIR/db_$FECHA.sql"; FILES="$BACKUP_DIR/files_$FECHA.tar.gz"
[ -f "$DBF" ] && [ -f "$FILES" ] || { echo "Faltan archivos del backup $FECHA"; exit 1; }

echo "Restaurando backup $FECHA ..."
[ -f "$NC_DIR/occ" ] && occ maintenance:mode --on || true
mysql -e "DROP DATABASE IF EXISTS \`$DB_NAME\`; CREATE DATABASE \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql "$DB_NAME" < "$DBF"
rm -rf "$NC_DIR" "$DATA_DIR"
tar -xzf "$FILES" -C /
chown -R www-data:www-data "$NC_DIR" "$DATA_DIR"
occ maintenance:data-fingerprint
occ maintenance:mode --off
echo "Restauración completada."
