FROM ghcr.io/symfony-cli/symfony-cli:v5 AS symfony-cli

FROM php:8.4-cli AS dev
WORKDIR /var/www/html

# System deps, PHP extension build deps, and PHP extensions.
RUN apt-get update && apt-get install -y --no-install-recommends \
        gnupg g++ procps openssl git zip unzip locales \
        zlib1g-dev libzip-dev libfreetype6-dev libpng-dev libwebp-dev libxpm-dev \
        libpq-dev libjpeg62-turbo-dev libicu-dev libgd-dev libonig-dev libxslt1-dev \
        acl vim wget nodejs npm apt-transport-https lsb-release ca-certificates \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" \
        pdo pdo_mysql opcache intl zip calendar dom mbstring exif gd xsl mysqli \
    && pecl install apcu && docker-php-ext-enable apcu \
    && corepack enable && corepack prepare yarn@stable --activate \
    && apt-get purge -y --auto-remove g++ \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Symfony CLI and Composer
COPY --link --from=symfony-cli /usr/local/bin/symfony /usr/local/bin/symfony
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer*

EXPOSE 8000
CMD ["symfony", "server:start", "--no-tls", "--port=8000", "--allow-http"]
