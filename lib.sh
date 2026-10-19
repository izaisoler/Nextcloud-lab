#!/bin/bash
# Funciones comunes. Se carga con: source "$(dirname "$0")/lib.sh"
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="/etc/nextcloud-lab.env"

# shellcheck disable=SC1091
source "$LAB_DIR/config.env"
# shellcheck disable=SC1090
[ -f "$SECRETS_FILE" ] && source "$SECRETS_FILE"

log()  { echo -e "\n\033[1;32m==> $*\033[0m"; }
warn() { echo -e "\033[1;33m[AVISO] $*\033[0m"; }
die()  { echo -e "\033[1;31m[ERROR] $*\033[0m"; exit 1; }

need_root() { [ "$EUID" -eq 0 ] || die "Ejecuta con sudo: sudo bash $0"; }

apt_install() { apt-get -o DPkg::Lock::Timeout=600 install -y "$@"; }

genpass() { echo "$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 18)Aa1"; }

# occ como www-data
occ() { (cd "$NC_DIR" && runuser -u www-data -- php occ "$@"); }
# occ pasando contraseña por variable de entorno
occ_pass() { local p="$1"; shift; (cd "$NC_DIR" && runuser -u www-data -- env OC_PASS="$p" php occ "$@"); }

require_nextcloud() {
  [ -f "$NC_DIR/occ" ] || die "Nextcloud no está instalado. Ejecuta antes: sudo bash 01-install-nextcloud.sh"
  [ -f "$SECRETS_FILE" ] || die "Falta $SECRETS_FILE. Ejecuta antes el paso 01."
}
