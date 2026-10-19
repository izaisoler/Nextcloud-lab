#!/bin/bash
# PASO 5: Backup automatizado de los datos (cron diario 3:00) + primer backup
source "$(dirname "$0")/lib.sh"
need_root
require_nextcloud

install -m 644 "$LAB_DIR/config.env" /etc/nextcloud-lab.conf
install -m 755 "$LAB_DIR/backup-nextcloud.sh"  /usr/local/bin/backup-nextcloud.sh
install -m 755 "$LAB_DIR/restore-nextcloud.sh" /usr/local/bin/restore-nextcloud.sh
install -m 755 "$LAB_DIR/test-restore.sh"      /usr/local/bin/test-restore-nextcloud.sh

cat > /etc/cron.d/backup-nextcloud <<EOF
0 3 * * * root /usr/local/bin/backup-nextcloud.sh >> /var/log/backup-nextcloud.log 2>&1
EOF
chmod 644 /etc/cron.d/backup-nextcloud

log "Lanzando primer backup"
/usr/local/bin/backup-nextcloud.sh
ls -lh "$BACKUP_DIR"
echo; echo "Cron programado:"; cat /etc/cron.d/backup-nextcloud

log "PASO 5 COMPLETADO"
echo "  Probar restauración: sudo test-restore-nextcloud.sh"
echo "  Restaurar el último:  sudo restore-nextcloud.sh"
