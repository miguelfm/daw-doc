#!/usr/bin/env bash
# Verifica que os tres servizos de documentación responden, están sans e teñen buscador.
#
# Uso: ./scripts/verificar.sh [-f COMPOSE_FILE]
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$RAIZ/compose.yaml"
if [[ ${1:-} == -f && -n ${2:-} ]]; then
    COMPOSE_FILE=$2
    shift 2
fi
COMPOSE=(docker compose -f "$COMPOSE_FILE")

porto() {
    "${COMPOSE[@]}" port "$1" "$2" 2>/dev/null | head -n 1 | sed 's/.*://'
}

fallos=0
ok()    { printf 'OK     %s\n' "$*"; }
fallo() { printf 'FALLA  %s\n' "$*" >&2; fallos=$((fallos + 1)); }

for svc in doc-php doc-web doc-laravel; do
    cid=$("${COMPOSE[@]}" ps -q "$svc" 2>/dev/null | head -n 1)
    if [[ -z $cid ]]; then
        fallo "$svc non está creado"
        continue
    fi
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cid")
    if [[ $health == healthy ]]; then
        ok "$svc healthy"
    else
        fallo "$svc estado de saúde: $health"
    fi
done

# doc-web só debe expoñer o porto 9292 (sen o 80 herdado de nginx:alpine).
web_img=$("${COMPOSE[@]}" config --images doc-web | head -n 1)
web_ports=$(docker image inspect -f '{{json .Config.ExposedPorts}}' "$web_img" 2>/dev/null || echo "")
if [[ $web_ports == '{"9292/tcp":{}}' ]]; then
    ok "doc-web expón só 9292/tcp"
else
    fallo "doc-web expón portos inesperados: $web_ports"
fi

comprobar_url() {
    local label=$1 url=$2 code
    code=$(curl -sS --max-time 8 -o /dev/null -w '%{http_code}' "$url" || echo 000)
    if [[ $code == 200 ]]; then
        ok "$label ($url)"
    else
        fallo "$label ($url) respondeu $code"
    fi
}

php_port=$(porto doc-php 80)
web_port=$(porto doc-web 9292)
laravel_port=$(porto doc-laravel 80)

comprobar_url "doc-php portada" "http://127.0.0.1:${php_port}/"
comprobar_url "doc-php busca" "http://127.0.0.1:${php_port}/search.html"
comprobar_url "doc-php Pagefind" "http://127.0.0.1:${php_port}/pagefind/pagefind-ui.js"
comprobar_url "doc-web portada" "http://127.0.0.1:${web_port}/"
comprobar_url "doc-web Pagefind" "http://127.0.0.1:${web_port}/pagefind/pagefind-ui.js"
comprobar_url "doc-laravel portada" "http://127.0.0.1:${laravel_port}/"
comprobar_url "doc-laravel busca" "http://127.0.0.1:${laravel_port}/search/search_index.json"

exit $((fallos > 0))
