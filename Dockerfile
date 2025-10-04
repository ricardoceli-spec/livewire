# syntax = docker/dockerfile:experimental

ARG PHP_VERSION=8.2
ARG NODE_VERSION=18
FROM fideloper/fly-laravel:${PHP_VERSION} as base

ARG PHP_VERSION

LABEL fly_launch_runtime="laravel"

WORKDIR /var/www/html

# ------------------------------------------------------------
# 1️⃣ Copiar archivos de Laravel
# ------------------------------------------------------------
COPY . .

# ------------------------------------------------------------
# 2️⃣ Definir variables mínimas para que Artisan no falle
# ------------------------------------------------------------
ENV APP_KEY=base64:SomeRandomKeyHere==
ENV APP_ENV=production
ENV DB_CONNECTION=mysql
ENV DB_HOST=127.0.0.1
ENV DB_PORT=3306
ENV DB_DATABASE=test
ENV DB_USERNAME=root
ENV DB_PASSWORD=secret

# ------------------------------------------------------------
# 3️⃣ Instalar dependencias PHP con Composer
# ------------------------------------------------------------
# Separamos la instalación y la ejecución de scripts
RUN composer install --optimize-autoloader --no-dev --no-scripts
RUN composer run-script post-autoload-dump

# ------------------------------------------------------------
# 4️⃣ Preparar Laravel
# ------------------------------------------------------------
RUN mkdir -p storage/logs
RUN php artisan optimize:clear
RUN chown -R www-data:www-data /var/www/html

# Configurar cron
RUN echo "MAILTO=\"\"\n* * * * * www-data /usr/bin/php /var/www/html/artisan schedule:run" > /etc/cron.d/laravel

# Ajustar middleware
RUN sed -i '/->withMiddleware(function (Middleware \$middleware) {/a \$middleware->trustProxies(at: "*");' bootstrap/app.php

# Copiar entrypoint si existe
RUN if [ -d .fly ]; then cp .fly/entrypoint.sh /entrypoint && chmod +x /entrypoint; fi

# ------------------------------------------------------------
# 5️⃣ Multi-stage build para assets de Node
# ------------------------------------------------------------
FROM node:${NODE_VERSION} as node_assets

WORKDIR /app
COPY . .
COPY --from=base /var/www/html/vendor /app/vendor

RUN if [ -f "vite.config.js" ]; then ASSET_CMD="build"; else ASSET_CMD="production"; fi \
    && if [ -f "yarn.lock" ]; then \
        yarn install --frozen-lockfile && yarn $ASSET_CMD; \
    elif [ -f "pnpm-lock.yaml" ]; then \
        corepack enable && corepack prepare pnpm@latest-8 --activate && pnpm install --frozen-lockfile && pnpm run $ASSET_CMD; \
    elif [ -f "package-lock.json" ]; then \
        npm ci --no-audit && npm run $ASSET_CMD; \
    else \
        npm install && npm run $ASSET_CMD; \
    fi

# ------------------------------------------------------------
# 6️⃣ Imagen final
# ------------------------------------------------------------
FROM base

COPY --from=node_assets /app/public /var/www/html/public-npm

RUN rsync -ar /var/www/html/public-npm/ /var/www/html/public/ \
    && rm -rf /var/www/html/public-npm \
    && chown -R www-data:www-data /var/www/html/public

EXPOSE 8080
