FROM php:8.2-apache

# Installation des extensions PHP nécessaires pour CakePHP
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install intl zip pdo_mysql

# Activation de mod_rewrite pour CakePHP
RUN a2enmod rewrite

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copie des fichiers CakePHP
COPY . .

# Droits sur les répertoires
RUN chown -R www-data:www-data /var/www/html/tmp /var/www/html/logs

EXPOSE 80
