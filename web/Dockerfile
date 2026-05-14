FROM php:7.4.33-fpm-alpine3.16

RUN apk add --no-cache \
  libicu-dev \
  libzip-dev \
  zip unzip git

COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions \
  intl zip

WORKDIR /var/www/html
COPY . .
RUN chown -R www-data:www-data /var/www/html
EXPOSE 9000
