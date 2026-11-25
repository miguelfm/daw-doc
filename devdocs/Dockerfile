# =============================================================
# DevDocs Lixeiro - Sen Ruby, sen imaxe de 4GB
# =============================================================
# Descarga todo o necesario directamente de devdocs.io con wget.
# Resultado final: nginx + ficheiros estáticos (~30-50MB)
# =============================================================

ARG DEVDOCS_LANGS="html css"

# ==================================
# STAGE 1: Descargar todo con wget
# ==================================
FROM alpine:3.24 AS downloader

ARG DEVDOCS_LANGS

RUN apk add --no-cache wget bash python3

WORKDIR /site

# Descargar a páxina principal
RUN wget -q https://devdocs.io/ -O index.html && echo "index.html OK"

# Extraer e descargar TODOS os recursos referenciados (CSS, JS, imaxes)
RUN for url in $(grep -oE '(href|src)="(/[^"]+)"' index.html | grep -oE '/[^"]+'); do \
      echo "Descargando: ${url}" && \
      mkdir -p "$(dirname ".${url}")" && \
      wget -q "https://devdocs.io${url}" -O ".${url}" 2>/dev/null || true; \
    done && \
    echo "=== Assets descargados ===" && \
    find ./assets -type f 2>/dev/null | wc -l && echo " ficheiros"

# Descargar o JS principal (pode estar ao final do HTML)
RUN grep -oE '/assets/[a-z0-9._-]+\.(js|css)' index.html | sort -u | while read -r url; do \
      mkdir -p "$(dirname ".${url}")" && \
      wget -q "https://devdocs.io${url}" -O ".${url}" 2>/dev/null && \
      echo "Asset: ${url} OK"; \
    done

# Descargar o manifest e a lista de docs
RUN wget -q "https://devdocs.io/docs/docs.json" -O docs/docs.json 2>/dev/null; \
    wget -q "https://devdocs.io/manifest.json" -O manifest.json 2>/dev/null; \
    wget -q "https://devdocs.io/opensearch.xml" -O opensearch.xml 2>/dev/null; \
    echo "Manifests OK"

# Descargar datos das documentacións solicitadas
RUN mkdir -p docs && \
    for lang in ${DEVDOCS_LANGS}; do \
      echo "=== Descargando docs: ${lang} ===" && \
      mkdir -p "docs/${lang}" && \
      wget -q "https://documents.devdocs.io/${lang}/index.json" -O "docs/${lang}/index.json" && \
      wget -q "https://documents.devdocs.io/${lang}/db.json" -O "docs/${lang}/db.json" && \
      echo "  ${lang} OK"; \
    done

# Desempaquetar db.json en ficheiros .html individuais para servizo 100% offline
COPY desempaquetar.py /tmp/desempaquetar.py
RUN python3 /tmp/desempaquetar.py && \
    sed -i 's|docs_origin:"//documents.devdocs.io"|docs_origin:"/docs"|g' assets/application-*.js

# Descargar imaxes e iconas
RUN mkdir -p images && \
    for img in favicon.ico images/icon-320.png images/fluid-icon.png \
               images/apple-icon-72.png images/apple-icon-76.png \
               images/apple-icon-114.png images/apple-icon-120.png \
               images/apple-icon-144.png images/apple-icon-152.png \
               images/apple-icon-160.png images/webkit-mask-icon.svg; do \
      mkdir -p "$(dirname "${img}")" && \
      wget -q "https://devdocs.io/${img}" -O "${img}" 2>/dev/null || true; \
    done && echo "Iconas OK"

# Verificar o que temos
RUN echo "=== RESUMO ===" && \
    du -sh . && \
    echo "Assets:" && ls -la assets/ 2>/dev/null && \
    echo "Docs:" && ls -la docs/ 2>/dev/null

# ==================================
# STAGE 2: Servir con nginx
# ==================================
FROM nginx:alpine

COPY --from=downloader /site /usr/share/nginx/html

RUN printf 'server {\n\
    listen 9292;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location /docs/ {\n\
        add_header Cache-Control "public, max-age=3600";\n\
    }\n\
    location /assets/ {\n\
        add_header Cache-Control "public, max-age=86400";\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 9292
# Na imaxe e non no Compose: válea tamén para o perfil doc de daw-dev
HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=10s --start-interval=1s \
    CMD wget -q --spider http://127.0.0.1:9292/ || exit 1
