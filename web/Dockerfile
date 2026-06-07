# web/Dockerfile - PHP 8.3-FPM-Alpine avec CakePHP3 support
# Support multi-platform: amd64, arm/v7, arm64

FROM php:8.3-fpm-alpine

# System dependencies
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
    freetype-dev \
    imagemagick-dev \
    shadow \
    netcat-openbsd

# PHP extensions (including those needed for CakePHP)
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
 && docker-php-ext-install \
    gd \
    intl \
    mbstring \
    zip \
    pdo \
    pdo_mysql \
    opcache

# Copy PHP configuration
COPY etc/php.ini /usr/local/etc/php/php.ini
COPY etc/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

# Copy application source
COPY . .

# Create necessary CakePHP directories
RUN mkdir -p src/Controller templates/Pages config logs tmp/cache tmp/sessions webroot/uploads \
 && chown -R www-data:www-data /var/www/html

# Install CakePHP dependencies (if composer.json exists)
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    fi

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 755 /var/www/html/logs \
 && chmod -R 755 /var/www/html/tmp

EXPOSE 9000

# Health check - verify PHP-FPM is working
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD php-fpm -t || exit 1

COPY scripts/wait-for-it.sh /wait-for-it.sh
RUN chmod 755 /wait-for-it.sh


CMD ["php-fpm", "-F"]