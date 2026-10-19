#!/bin/bash
# Ejecuta los 5 pasos seguidos.
#   sudo bash run-all.sh            -> todos
#   sudo bash run-all.sh 02 05      -> solo los pasos indicados
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
[ "$EUID" -eq 0 ] || { echo "Ejecuta con: sudo bash run-all.sh"; exit 1; }

if [ $# -gt 0 ]; then
  for n in "$@"; do bash "$DIR"/"$n"-*.sh; done
else
  for s in "$DIR"/0[1-5]-*.sh; do bash "$s"; done
fi

source "$DIR/config.env"
[ -f /etc/nextcloud-lab.env ] && source /etc/nextcloud-lab.env
echo
echo "=============================================="
echo " TODO LISTO"
echo " URL (desde el navegador de tu PC): http://$PUBLIC_HOST$ALIAS"
echo " admin / ${ADMIN_PASS:-?}"
echo " ana, luis, marta / ${USER_PASS:-?}"
echo " (contraseñas guardadas en /etc/nextcloud-lab.env)"
echo "=============================================="
