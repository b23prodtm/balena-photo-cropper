FROM php:7.4-fpm
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    zip \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libssl-dev \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
 
RUN docker-php-ext-install \
    pdo_mysql \
    mysqli \
    mbstring \
    xml \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd
 
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
 
WORKDIR /var/www/html
 
COPY . /var/www/html
 
RUN if [ -f "composer.json" ]; then composer install --no-dev --optimize-autoloader; fi
 
RUN chown -R www-data:www-data /var/www/html
 
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:9000/ping 2>/dev/null || exit 1
 
EXPOSE 9000
 
CMD ["php-fpm"]
