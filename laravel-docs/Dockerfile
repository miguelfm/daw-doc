# =============================================================
# Dockerfile para Documentación Offline de Laravel con Buscador
# =============================================================
# Multi-stage build:
#   1. Clona os docs de Laravel desde GitHub
#   2. Constrúe o sitio estático con MkDocs + Material (inclúe buscador offline)
#   3. Serve con nginx (imaxe final lixeira)
# =============================================================

ARG LARAVEL_VERSION=13.x

# ==================================
# STAGE 1: Construción
# ==================================
FROM python:3.12-slim AS builder

ARG LARAVEL_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    mkdocs==1.6.* \
    mkdocs-material==9.* \
    pymdown-extensions \
    pygments \
    pyyaml

RUN git clone --depth 1 --branch ${LARAVEL_VERSION} \
    https://github.com/laravel/docs.git /docs

COPY build-nav.py /build-nav.py

RUN python /build-nav.py

RUN mkdocs build -f /mkdocs.yml -d /site 2>&1 && \
    ls -la /site/ && \
    test -f /site/index.html || (echo "ERRO: index.html non xerado!" && exit 1)

# ==================================
# STAGE 2: Servizo (nginx lixeiro)
# ==================================
FROM nginx:alpine

COPY --from=builder /site /usr/share/nginx/html

RUN cat > /etc/nginx/conf.d/default.conf << 'NGINX'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    add_header X-Content-Type-Options nosniff;

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location ~* \.json$ {
        add_header Content-Type application/json;
    }

    location / {
        try_files $uri $uri/ $uri.html /index.html;
    }
}
NGINX

EXPOSE 80
# Na imaxe e non no Compose: válea tamén para o perfil doc de daw-dev
HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=10s --start-interval=1s \
    CMD wget -q --spider http://127.0.0.1/ || exit 1

LABEL maintainer="DAW Docencia"
LABEL description="Documentación offline de Laravel con buscador integrado"
