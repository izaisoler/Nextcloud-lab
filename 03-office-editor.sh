#!/bin/bash
# PASO 3: Editor ofimático colaborativo (Nextcloud Office + Collabora integrado)
source "$(dirname "$0")/lib.sh"
need_root
require_nextcloud

ARCH=$(uname -m)
MEM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
[ "$MEM_MB" -lt 2000 ] && warn "Solo hay ${MEM_MB} MB de RAM: el editor irá lento (recomendado 2 GB+)"

log "Instalando Nextcloud Office"
occ app:install richdocuments || occ app:enable richdocuments

if [ "$ARCH" = "x86_64" ]; then
  log "Instalando servidor Collabora integrado (CODE)"
  occ app:install richdocumentscode || occ app:enable richdocumentscode
else
  warn "Arquitectura $ARCH: el CODE integrado solo funciona en x86_64."
  warn "Usa Collabora/ONLYOFFICE en Docker como servidor externo."
fi

systemctl restart apache2

log "PASO 3 COMPLETADO"
echo "  Prueba: en Nextcloud, '+' → Documento; compártelo con 'ana' (edición)"
echo "  y ábrelo a la vez con admin y ana (ventana de incógnito)."
echo "  Si el editor no carga: Ajustes de administración → Nextcloud Office."
