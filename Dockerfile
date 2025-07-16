FROM php:8.2-apache

# Instalar dependencias del sistema y extensiones PHP
RUN apt-get update && apt-get install -y \
    curl gnupg2 unzip git zip libicu-dev libxml2-dev libzip-dev \
    libpng-dev libjpeg-dev libfreetype6-dev libonig-dev \
    libxslt1-dev libmagickwand-dev libpq-dev libssl-dev \
    libc-client-dev libkrb5-dev libcurl4-openssl-dev zlib1g-dev \
    nodejs npm \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install intl pdo pdo_mysql pdo_pgsql zip xml gd opcache bcmath imap xsl

# Configurar PHP para producción (memoria y rendimiento)
RUN echo "memory_limit=512M\nzend.assertions=-1" > /usr/local/etc/php/conf.d/mautic.ini

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establecer directorio de trabajo
WORKDIR /var/www/html

# Copiar archivos de Mautic al contenedor
COPY . .

# Instalar dependencias de PHP y JS
RUN COMPOSER_MEMORY_LIMIT=-1 composer install --no-interaction --prefer-dist --no-dev

# Verificar que Composer haya generado vendor/autoload.php
RUN test -f /var/www/html/vendor/autoload.php || (echo "❌ composer install falló" && exit 1)

# Verificar que PostgreSQL esté habilitado
RUN php -m | grep pdo_pgsql || (echo "❌ pdo_pgsql NO está activo" && exit 1)

# Asignar permisos a Apache y activar mod_rewrite
RUN chown -R www-data:www-data /var/www/html && a2enmod rewrite

# Exponer el puerto web
EXPOSE 80
