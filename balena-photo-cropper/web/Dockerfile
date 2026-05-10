FROM php:8.2-apache
RUN apt-get update && apt-get install -y libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install intl zip
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80
