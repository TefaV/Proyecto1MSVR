# Usa una imagen oficial de PHP con Apache
FROM php:8.2-apache

# Instalar extensiones necesarias
RUN apt-get update && apt-get install -y libpng-dev zip unzip \
    && docker-php-ext-install pdo pdo_mysql gd

# Instalar Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configurar el directorio de trabajo
WORKDIR /var/www/html

# Copiar primero composer.json y composer.lock para aprovechar la caché de Docker
COPY composer.json composer.lock /var/www/html/

# Copiar .env.example como .env para evitar errores en composer install
COPY .env.example /var/www/html/.env

# Instalar dependencias de Laravel SIN ejecutar scripts
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-scripts

# Copiar todo el proyecto
COPY . /var/www/html/

# Dar permisos a carpetas necesarias
RUN chmod -R 777 storage bootstrap/cache

# Crear archivo database.sqlite si no existe y dar permisos
RUN mkdir -p database \
    && touch database/database.sqlite \
    && chmod -R 777 database/database.sqlite

# Configurar Apache para que sirva desde el directorio public de Laravel
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf \
    && echo '    DocumentRoot /var/www/html/public' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    <Directory /var/www/html/public>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf \
    && echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf \
    && echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

# Habilitar mod_rewrite y headers en Apache
RUN a2enmod rewrite headers

# Exponer el puerto 80
EXPOSE 80

# Comando de inicio: optimizar y migrar, luego levantar Apache
CMD php artisan optimize && php artisan migrate --force && apache2-foreground
