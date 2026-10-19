#!/bin/bash
# PASO 1: Desplegar Nextcloud sobre Apache + PHP + MariaDB (Ubuntu 22.04)
source "$(dirname "$0")/lib.sh"
need_root

log "Instalando dependencias (si apt está ocupado, espera solo)"
apt-get -o DPkg::Lock::Timeout=600 update
apt_install apache2 mariadb-server libapache2-mod-php php php-mysql php-curl php-gd \
  php-xml php-mbstring php-zip php-intl php-bcmath php-gmp php-imagick php-apcu \
  bzip2 curl openssl

PHPV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
log "PHP detectado: $PHPV  |  Nextcloud a instalar: $NC_VERSION"
case "$PHPV" in 8.0|7.*) die "PHP $PHPV es demasiado antiguo para Nextcloud $NC_VERSION";; esac

# --- Contraseñas generadas automáticamente (no se guardan en el repo) ---
if [ ! -f "$SECRETS_FILE" ]; then
  log "Generando contraseñas en $SECRETS_FILE"
  ( umask 077
    cat > "$SECRETS_FILE" <<EOF
DB_PASS="$(genpass)"
ADMIN_PASS="$(genpass)"
USER_PASS="$(genpass)"
EOF
  )
fi
# shellcheck disable=SC1090
source "$SECRETS_FILE"

# --- Descarga ---
if [ ! -f "$NC_DIR/occ" ]; then
  log "Descargando Nextcloud $NC_VERSION"
  cd /tmp
  URL="https://download.nextcloud.com/server/releases/nextcloud-$NC_VERSION.tar.bz2"
  curl -fSL -o nextcloud.tar.bz2 "$URL"
  if curl -fsSL -o nextcloud.tar.bz2.sha256 "$URL.sha256"; then
    echo "$(cut -d' ' -f1 nextcloud.tar.bz2.sha256)  nextcloud.tar.bz2" | sha256sum -c -
  else
    warn "No se pudo descargar el checksum; se omite la verificación"
  fi
  tar -xjf nextcloud.tar.bz2
  mv nextcloud "$NC_DIR"
  rm -f nextcloud.tar.bz2 nextcloud.tar.bz2.sha256
fi
mkdir -p "$DATA_DIR"
chown -R www-data:www-data "$NC_DIR" "$DATA_DIR"

# --- Base de datos ---
log "Configurando MariaDB"
systemctl enable --now mariadb
mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;"

# --- Apache ---
log "Configurando Apache (Alias $ALIAS)"
cat > /etc/apache2/conf-available/nextcloud.conf <<EOF
Alias $ALIAS "$NC_DIR/"
<Directory $NC_DIR/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
    <IfModule mod_dav.c>
        Dav off
    </IfModule>
</Directory>
EOF
a2enmod rewrite headers env dir mime >/dev/null
a2enconf nextcloud >/dev/null
sed -i 's/^memory_limit = .*/memory_limit = 512M/' "/etc/php/$PHPV/apache2/php.ini"
sed -i 's/^memory_limit = .*/memory_limit = 512M/' "/etc/php/$PHPV/cli/php.ini"
systemctl restart apache2

# --- Instalación de Nextcloud ---
if occ status 2>/dev/null | grep -q 'installed: true'; then
  warn "Nextcloud ya estaba instalado; se omite maintenance:install"
else
  log "Instalando Nextcloud (occ maintenance:install)"
  occ maintenance:install \
    --database mysql --database-name "$DB_NAME" \
    --database-user "$DB_USER" --database-pass "$DB_PASS" \
    --admin-user "$ADMIN_USER" --admin-pass "$ADMIN_PASS" \
    --data-dir "$DATA_DIR"
fi

VM_IP=$(hostname -I | awk '{print $1}')
occ config:system:set trusted_domains 1 --value="localhost"
occ config:system:set trusted_domains 2 --value="$PUBLIC_HOST"
occ config:system:set trusted_domains 3 --value="$VM_IP"
occ config:system:set overwrite.cli.url --value="http://$PUBLIC_HOST$ALIAS"
occ config:system:set htaccess.RewriteBase --value="$ALIAS"
occ config:system:set default_phone_region --value="ES"
occ maintenance:update:htaccess
systemctl reload apache2

log "PASO 1 COMPLETADO"
echo "  URL (desde tu PC): http://$PUBLIC_HOST$ALIAS"
echo "  Usuario: $ADMIN_USER    Contraseña: $ADMIN_PASS"
