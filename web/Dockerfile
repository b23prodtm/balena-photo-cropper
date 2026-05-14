FROM php:8.3-fpm-alpine

# System deps
RUN apk add --no-cache \
    bash \
    git \
    curl \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    unzip \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev

# PHP extensions
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
 && docker-php-ext-install \
    gd \
    intl \
    mbstring \
    zip \
    pdo \
    pdo_mysql

# PHP config
COPY etc/php.ini /usr/local/etc/php/php.ini
COPY etc/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html
COPY . .

# Permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000

CMD ["php-fpm", "-F"]
