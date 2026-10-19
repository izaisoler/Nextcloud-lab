#!/bin/bash
# PASO 4: Comparativa SaaS de terceros vs suite propia.
# Es un apartado de redacción: genera las plantillas para rellenar con tu experiencia.
source "$(dirname "$0")/lib.sh"
need_root

OUT="${SUDO_USER:+/home/$SUDO_USER}"
OUT="${OUT:-/root}/entrega"
mkdir -p "$OUT"
cp "$LAB_DIR/docs/comparativa-saas.md" "$OUT/"
cp "$LAB_DIR/docs/matriz-accesos.md"   "$OUT/"
[ -n "${SUDO_USER:-}" ] && chown -R "$SUDO_USER":"$SUDO_USER" "$OUT"

# Datos reales para la comparativa
{
  echo "# Datos reales de esta instalación ($(date +%F))"
  echo "- Nextcloud: $(occ status 2>/dev/null | grep -i versionstring | awk -F: '{print $2}' | xargs)"
  echo "- PHP: $(php -r 'echo PHP_VERSION;')"
  echo "- RAM de la VM: $(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) MB"
  echo "- Espacio usado por Nextcloud: $(du -sh "$NC_DIR" "$DATA_DIR" 2>/dev/null | awk '{s=s" "$1" ("$2")"} END{print s}')"
} > "$OUT/datos-instalacion.md"

log "PASO 4 COMPLETADO"
echo "  Plantillas creadas en: $OUT"
echo "  Rellena comparativa-saas.md y matriz-accesos.md con tu experiencia."
