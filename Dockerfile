FROM fideloper/fly-laravel:8.2 as base

# Copiar el código
COPY . /var/www/html
WORKDIR /var/www/html

#  Instalar dependencias de PHP
RUN composer install --optimize-autoloader --no-dev

#  Crear carpetas necesarias y limpiar cache
RUN mkdir -p storage/logs
RUN php artisan optimize:clear

# Ajustar permisos
RUN chown -R www-data:www-data /var/www/html

# Configurar cron job
RUN echo "MAILTO=\"\"\n* * * * * www-data /usr/bin/php /var/www/html/artisan schedule:run" > /etc/cron.d/laravel

#  Ajustar middleware con sed (compatible)
RUN sed -i '/->withMiddleware(function (Middleware \$middleware) {/a \$middleware->trustProxies(at: "*");' bootstrap/app.php

#  Copiar entrypoint si existe
RUN if [ -d .fly ]; then cp .fly/entrypoint.sh /entrypoint && chmod +x /entrypoint; fi

# ------------------------------------------------------------
# Multi-stage build para Node (assets)
# ------------------------------------------------------------
FROM node:18 as node_assets
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
# Imagen final
# ------------------------------------------------------------
FROM base
COPY --from=node_assets /app/public /var/www/html/public-npm

RUN rsync -ar /var/www/html/public-npm/ /var/www/html/public/ \
    && rm -rf /var/www/html/public-npm \
    && chown -R www-data:www-data /var/www/html/public

EXPOSE 8080
