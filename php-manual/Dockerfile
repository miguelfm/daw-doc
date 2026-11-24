# =============================================================
# PHP Manual Offline con Buscador (Pagefind)
# =============================================================
# Multi-stage build:
#   1. Descarga o manual HTML de php.net
#   2. Indexa con Pagefind (buscador estático con ranking)
#   3. Inxecta barra de busca en todas as páxinas
#   4. Serve con nginx
# =============================================================

ARG PHP_MANUAL_LANG=en

# ==================================
# STAGE 1: Descarga e indexación
# ==================================
FROM node:22-alpine AS builder

ARG PHP_MANUAL_LANG

RUN apk add --no-cache curl tar

# Instalar Pagefind
RUN npm install -g pagefind

# Descargar o manual de PHP
RUN mkdir -p /site && \
    curl -L "https://www.php.net/distributions/manual/php_manual_${PHP_MANUAL_LANG}.tar.gz" \
    | tar -xz -C /site --strip-components=1

# Crear páxina de busca dedicada
RUN cat > /site/search.html << 'SEARCHPAGE'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Manual - Buscar</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: #f4f4f8;
            color: #333;
        }
        .header {
            background: #4F5B93;
            color: white;
            padding: 1.5rem 2rem;
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        .header h1 { font-size: 1.5rem; font-weight: 600; }
        .header a { color: #c5cae9; text-decoration: none; font-size: 0.9rem; }
        .header a:hover { color: white; }
        .search-container {
            max-width: 900px;
            margin: 2rem auto;
            padding: 0 1.5rem;
        }
        .pagefind-ui .pagefind-ui__search-input {
            font-size: 1.1rem !important;
            padding: 0.8rem 1rem !important;
            border-radius: 8px !important;
            border: 2px solid #4F5B93 !important;
        }
        .pagefind-ui .pagefind-ui__search-input:focus {
            outline: none !important;
            border-color: #7986cb !important;
            box-shadow: 0 0 0 3px rgba(79, 91, 147, 0.2) !important;
        }
        .pagefind-ui .pagefind-ui__result-link {
            color: #4F5B93 !important;
            font-weight: 600 !important;
        }
        .tip {
            margin-top: 1.5rem;
            padding: 1rem;
            background: #e8eaf6;
            border-left: 4px solid #4F5B93;
            border-radius: 4px;
            font-size: 0.9rem;
            color: #555;
        }
    </style>
    <link href="/pagefind/pagefind-ui.css" rel="stylesheet">
</head>
<body>
    <div class="header">
        <h1>PHP Manual - Busca</h1>
        <a href="/index.html">← Volver ao índice</a>
    </div>
    <div class="search-container">
        <div id="search"></div>
        <div class="tip">
            Podes buscar funcións (p.ex. <code>array_map</code>), conceptos (<code>closures</code>),
            ou calquera termo da documentación de PHP.
        </div>
    </div>
    <script src="/pagefind/pagefind-ui.js"></script>
    <script>
        new PagefindUI({
            element: "#search",
            showSubResults: true,
            showImages: false,
            autofocus: true,
            translations: {
                placeholder: "Buscar na documentación de PHP...",
                zero_results: "Non se atoparon resultados para «[SEARCH_TERM]»",
                many_results: "[COUNT] resultados",
                one_result: "1 resultado",
            }
        });
    </script>
</body>
</html>
SEARCHPAGE

# Indexar con Pagefind
# --glob filtra só ficheiros relevantes do manual PHP
RUN pagefind \
    --site /site \
    --glob "*.html" \
    --exclude-selectors "nav, .navbar, footer, .layout-menu, #breadcrumbs-inner, .next, .prev" \
    --verbose

# ==================================
# STAGE 2: Servizo con nginx
# ==================================
FROM nginx:alpine

COPY --from=builder /site /usr/share/nginx/html

# Configuración de nginx con sub_filter para inxectar
# un botón de busca flutuante en todas as páxinas do manual
RUN cat > /etc/nginx/conf.d/default.conf << 'NGINX'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Necesario para que sub_filter funcione
    gzip off;

    # Inxectar barra de busca flutuante en todas as páxinas HTML
    sub_filter '</body>' '
        <div id="php-search-float" style="position:fixed;bottom:20px;right:20px;z-index:9999;">
            <a href="/search.html"
               style="display:flex;align-items:center;gap:8px;
                      background:#4F5B93;color:white;
                      padding:12px 20px;border-radius:50px;
                      text-decoration:none;font-family:sans-serif;
                      font-size:15px;font-weight:600;
                      box-shadow:0 4px 12px rgba(0,0,0,0.3);
                      transition:transform 0.2s,box-shadow 0.2s;"
               onmouseover="this.style.transform=&apos;scale(1.05)&apos;;this.style.boxShadow=&apos;0 6px 16px rgba(0,0,0,0.4)&apos;"
               onmouseout="this.style.transform=&apos;scale(1)&apos;;this.style.boxShadow=&apos;0 4px 12px rgba(0,0,0,0.3)&apos;">
                <svg width="18" height="18" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                    <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
                </svg>
                Buscar
            </a>
        </div>
    </body>';
    sub_filter_once on;
    sub_filter_types text/html;

    # Cache para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Ficheiros do índice de Pagefind
    location /pagefind/ {
        add_header Cache-Control "public, max-age=86400";
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

EXPOSE 80

LABEL maintainer="DAW Docencia"
LABEL description="Manual de PHP offline con buscador Pagefind"
