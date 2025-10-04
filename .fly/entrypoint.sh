#!/usr/bin/env sh

# Ejecutar scripts de usuario si existen
for f in /var/www/html/.fly/scripts/*.sh; do
    # Salir si algún script falla
    bash "$f" -e
done

# Ajustar permisos
chown -R www-data:www-data /var/www/html

# Ejecutar Laravel Artisan al iniciar el contenedor
php /var/www/html/artisan package:discover --ansi
# Opcional: migraciones automáticas
# php /var/www/html/artisan migrate --force

# Ejecutar supervisord o comando pasado al contenedor
if [ $# -gt 0 ]; then
    exec "$@"
else
    exec supervisord -c /etc/supervisor/supervisord.conf
fi
