# syntax = docker/dockerfile:experimental

ARG PHP_VERSION=8.2
ARG NODE_VERSION=18
FROM fideloper/fly-laravel:${PHP_VERSION} as base

WORKDIR /var/www/html

# ------------------------------------------------------------
# 1️⃣ Copiar código de Laravel
# ------------------------------------------------------------
COPY . .

# ------------------------------------------------------------
# 2️⃣ Instalar dependencias PHP con Composer sin scripts
# ------------------------------------------------------------
RUN composer install --optimize-autoloader --no-dev --no-scripts

# ------------------------------------------------------------
# 3️⃣ Preparar Laravel: storage y permisos
# ------------------------------------------------------------
RUN mkdir -p storage/logs \
    && chown -R www-data:www-data /var/www/html

# ------------------------------------------------------------
# 4️⃣ Multi-stage build: Generar assets de Node
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
# 5️⃣ Imagen final
# ------------------------------------------------------------
FROM base

# Copiar assets generados
COPY --from=node_assets /app/public /var/www/html/public-npm
RUN rsync -ar /var/www/html/public-npm/ /var/www/html/public/ \
    && rm -rf /var/www/html/public-npm \
    && chown -R www-data:www-data /var/www/html/public

# Copiar entrypoint
COPY .fly/entrypoint.sh /entrypoint
RUN chmod +x /entrypoint

EXPOSE 8080
ENTRYPOINT ["/entrypoint"]
