FROM php:8.4-fpm-alpine

# Install dependencies for MariaDB, GD, etc.
RUN apk add --no-cache \
    mariadb-connector-c-dev \
    freetype-dev \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    icu-dev \
    icu-data-full \
    tzdata \
    git \
    unzip \
    libjpeg-turbo-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mbstring \
        intl \
        gd \
        zip \
        opcache

# System dependencies
RUN apk add --no-cache \
    bash \
    curl \
    netcat-openbsd \
    php84-intl \
    imagemagick-dev \
    shadow


# Copy PHP configuration
COPY etc/php.ini /usr/local/etc/php/php.ini
COPY etc/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# --- SECURE SETUP ---
# 1. Create project in /var/www/cakephp (NOT document root)
WORKDIR /var/www
RUN composer create-project --prefer-dist cakephp/app:^5.0 cakephp && \
    # 2. Fix permissions (FPM runs as www-data)
    chown -R www-data:www-data /var/www/cakephp && \
    chmod -R 775 /var/www/cakephp/tmp && \
    chmod -R 775 /var/www/cakephp/logs && \
    # 3. Configure PHP-FPM for CakePHP
    echo "php_admin_value[error_log] = /var/www/cakephp/logs/php-fpm.log" >> /usr/local/etc/php-fpm.d/www.conf && \
    echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# 4. Set working directory for CLI commands
WORKDIR /var/www/cakephp

# Copy application source
COPY . .

# Fix perms
RUN chown -R www-data:www-data /var/www/cakephp

# Install CakePHP dependencies (if composer.json exists)
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    fi

EXPOSE 9000

# Health check - verify PHP-FPM is working
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD php-fpm -t || exit 1

COPY scripts/wait-for-it.sh /wait-for-it.sh
RUN chmod 755 /wait-for-it.sh

CMD ["php-fpm", "-F"]
