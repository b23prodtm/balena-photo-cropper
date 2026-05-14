FROM php:8.2-apache
RUN apt-get update && apt-get install -y \
  libicu-dev \
  libzip-dev \
  zip unzip git \
  openssl-provider-legacy libssl3t64 \
    && rm -rf /var/lib/apt/lists/*

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions
RUN install-php-extensions \
  intl zip

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80
