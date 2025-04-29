#!/bin/bash

# Esperar a que la base de datos esté lista (puede ser útil si tienes una base de datos externa)
# sleep 10

# Generar la clave de la aplicación
php artisan key:generate --force

# Optimizar la configuración
php artisan optimize

# Ejecutar las migraciones
php artisan migrate --force

# Ejecutar los seeders
php artisan db:seed --force

# Iniciar Apache en primer plano
exec "$@"
