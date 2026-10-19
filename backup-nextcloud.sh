#!/bin/bash
# Backup de Nextcloud: BD + código + datos, con modo mantenimiento.
set -euo pipefail
source /etc/nextcloud-lab.conf

FECHA=$(date +%F_%H-%M)
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
occ() { (cd "$NC_DIR" && runuser -u www-data -- php occ "$@"); }

occ maintenance:mode --on
trap 'occ maintenance:mode --off' EXIT

mysqldump --single-transaction "$DB_NAME" > "$BACKUP_DIR/db_$FECHA.sql"
tar -czf "$BACKUP_DIR/files_$FECHA.tar.gz" -C / "${NC_DIR#/}" "${DATA_DIR#/}"
find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -delete

echo "[$(date '+%F %T')] Backup Nextcloud OK: $FECHA"
