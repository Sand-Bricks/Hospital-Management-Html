# Use official PHP-FPM image
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www/html

# Install minimal required system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    git unzip libzip-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy composer files first (cache optimization)
COPY composer.json composer.lock* ./

# Install PHP extensions and Composer dependencies if present
RUN if [ -f composer.json ]; then \
        docker-php-ext-install pdo_mysql zip intl; \
        composer install --no-dev --optimize-autoloader; \
    fi

# Copy the rest of the application (including assets/plugins)
COPY . .

# Nginx setup
RUN rm -f /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Optional: Add healthcheck for Docker
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:8087/ || exit 1

# Expose port
EXPOSE 8087

# Start PHP-FPM and Nginx in foreground
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
