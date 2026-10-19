# Nextcloud Lab (UD · Práctica guiada)

Automatiza las 5 partes de la práctica sobre el stack de la UD1 (Ubuntu 22.04 + Apache + MariaDB).

| Script | Qué hace |
|---|---|
| `01-install-nextcloud.sh` | Instala dependencias, descarga Nextcloud, crea BD, configura Apache e instala |
| `02-users-roles.sh` | Crea grupos, usuarios con roles/cuotas y carpetas compartidas |
| `03-office-editor.sh` | Instala Nextcloud Office con Collabora integrado |
| `04-saas-comparison.sh` | Genera las plantillas de la comparativa y la matriz de accesos |
| `05-backup.sh` | Instala el backup automático (cron 3:00), lanza el primero y deja listo el restore |
| `run-all.sh` | Ejecuta los cinco seguidos |

## Uso (en la VM)
```
sudo apt install git
git clone https://github.com/TU_USUARIO/nextcloud-lab.git
cd nextcloud-lab
sudo bash run-all.sh
```
Usa siempre `bash script.sh`: así funciona aunque el archivo haya perdido el permiso de ejecución al pasar por Windows.
También puedes lanzar pasos sueltos: `sudo bash run-all.sh 02 05`.

Al terminar entra desde el navegador de tu PC en **http://localhost:8080/nextcloud**
(requiere la regla de reenvío de VirtualBox 8080 → 80).

## Después
- Probar la restauración: `sudo test-restore-nextcloud.sh`
- Restaurar el último backup: `sudo restore-nextcloud.sh`
- Plantillas para entregar: carpeta `~/entrega` (paso 4)

## Seguridad
Las contraseñas **no están en el repo**: se generan en el paso 01 y se guardan en
`/etc/nextcloud-lab.env` (permisos 600). Los backups contienen toda la BD y los datos:
nunca los subas a GitHub (el `.gitignore` ya los excluye).

## Notas
- Nextcloud 32 es compatible con PHP 8.1 (Ubuntu 22.04) pero su soporte terminó en sept. 2026: vale para prácticas, no para producción.
- Cambia versión, puertos o rutas en `config.env`.
