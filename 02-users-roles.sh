#!/bin/bash
# PASO 2: Usuarios con distintos roles + carpetas compartidas para comparar accesos
source "$(dirname "$0")/lib.sh"
need_root
require_nextcloud

BASE="http://localhost$ALIAS"

log "Creando grupos"
for g in profesores alumnos; do
  occ group:list 2>/dev/null | grep -q "^  - $g:" || occ group:add "$g" || true
done

log "Creando usuarios"
add_user() {  # usuario  "Nombre"  grupo  cuota
  if occ user:info "$1" >/dev/null 2>&1; then
    warn "El usuario $1 ya existe"
  else
    occ_pass "$USER_PASS" user:add --password-from-env --display-name="$2" --group="$3" "$1"
  fi
  occ user:setting "$1" files quota "$4"
}
add_user ana   "Ana Profesora" profesores 5GB
add_user luis  "Luis Alumno"   alumnos    1GB
add_user marta "Marta Alumna"  alumnos    1GB

log "Ana como administradora del grupo 'profesores' (rol Group admin)"
curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "OCS-APIRequest: true" -X POST \
  "$BASE/ocs/v2.php/cloud/users/ana/subadmins?format=json" -d groupid=profesores \
  | grep -q '"statuscode":200' && echo "OK" || warn "No se pudo asignar; hazlo en Usuarios → Ana → Rol"

log "Carpetas compartidas desde admin"
mk_share() {  # carpeta grupo permisos
  curl -s -u "$ADMIN_USER:$ADMIN_PASS" -X MKCOL "$BASE/remote.php/dav/files/$ADMIN_USER/$1" >/dev/null || true
  curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "OCS-APIRequest: true" -X POST \
    "$BASE/ocs/v2.php/apps/files_sharing/api/v1/shares?format=json" \
    -d "path=/$1" -d shareType=1 -d "shareWith=$2" -d "permissions=$3" >/dev/null \
    && echo "  /$1 -> grupo $2 (permisos $3)" || warn "No se pudo compartir $1"
}
mk_share Material  alumnos    1    # solo lectura
mk_share Examenes  profesores 15   # lectura + edición + creación + borrado

log "PASO 2 COMPLETADO"
echo "  Usuarios: ana (profesores, group admin), luis y marta (alumnos)"
echo "  Contraseña de los tres: $USER_PASS"
echo "  Para comparar accesos: entra con cada uno en ventanas de incógnito"
echo "  y rellena docs/matriz-accesos.md (se copia en el paso 04)."
