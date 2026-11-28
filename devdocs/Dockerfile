# =============================================================
# Referencia web sen conexión (MDN Web Docs a través de DevDocs)
# =============================================================
# Multi-stage build:
#   1. Descarga de documents.devdocs.io as documentacións indicadas e garda
#      cada páxina como HTML estático (build-site.py)
#   2. Indexa con Pagefind (buscador estático)
#   3. Serve con nginx
# Non inclúe a aplicación de DevDocs: só funciona servida desde devdocs.io e,
# fóra del, descarga os documentos de Internet.
# =============================================================

# Documentacións de DevDocs (slugs de https://devdocs.io/docs/docs.json)
ARG DEVDOCS_LANGS="html http css"

# ==================================
# STAGE 1: Descarga e indexación
# ==================================
FROM node:26-alpine AS builder

ARG DEVDOCS_LANGS

RUN apk add --no-cache python3 && npm install -g pagefind

COPY build-site.py /build-site.py
RUN SITE_DIR=/site python3 /build-site.py ${DEVDOCS_LANGS}

RUN pagefind --site /site

# ==================================
# STAGE 2: Servizo con nginx (sen EXPOSE 80 herdado de nginx:alpine)
# ==================================
FROM alpine:3.24

RUN apk add --no-cache nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir -p /usr/share/nginx/html /run/nginx

COPY --from=builder /site /usr/share/nginx/html

# As ligazóns das páxinas van sen .html, como en DevDocs.
RUN cat > /etc/nginx/http.d/default.conf << 'NGINX'
server {
    listen 9292;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;
    charset utf-8;

    location /pagefind/ {
        add_header Cache-Control "public, max-age=86400";
    }

    location / {
        try_files $uri $uri.html $uri/ =404;
    }
}
NGINX

EXPOSE 9292
# Na imaxe e non no Compose: válea tamén para o perfil doc de daw-dev
HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=10s --start-interval=1s \
    CMD wget -q --spider http://127.0.0.1:9292/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

LABEL description="Offline web reference (MDN Web Docs via DevDocs) with Pagefind search"
