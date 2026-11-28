#!/usr/bin/env bash
# Instala e arranca a documentación sen conexión, sen rede.
#
# Uso no paquete (na copia Git, executa scripts/instalar.sh):
#   ./instalar.sh            carga as imaxes que falten e arranca os servizos
#   ./instalar.sh estado     amosa os contedores
#   ./instalar.sh parar      para os contedores, sen borrar as imaxes
#
# Cada imaxe que falte cárgase do seu arquivo (daw-doc-php.tar.gz...),
# despois de comprobar o SHA256. Os contedores levan restart:
# unless-stopped, e volven arrancar cada vez que arranca Docker.
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ${AQUI##*/} == scripts && ! -f "$AQUI/compose.yaml" ]]; then
    AQUI="$(cd "$AQUI/.." && pwd)"
fi
cd "$AQUI"
COMPOSE=(docker compose -f "$AQUI/compose.yaml")

# En WSL, Docker pode tardar uns segundos en arrancar coa distribución
for _ in $(seq 60); do
    docker info >/dev/null 2>&1 && break
    sleep 1
done
docker info >/dev/null 2>&1 || {
    echo "Docker non está dispoñíbel para este usuario." >&2
    exit 1
}

case "${1:-instalar}" in
    estado)
        "${COMPOSE[@]}" ps
        exit 0
        ;;
    parar)
        "${COMPOSE[@]}" stop
        exit 0
        ;;
    instalar) ;;
    *)
        echo "Uso: $0 [instalar|estado|parar]" >&2
        exit 2
        ;;
esac

while read -r imaxe; do
    docker image inspect "$imaxe" </dev/null >/dev/null 2>&1 && continue
    arquivo="$(basename "${imaxe%%:*}").tar.gz"
    [ -f "$arquivo" ] || {
        echo "Falta a imaxe $imaxe e non está $arquivo." >&2
        exit 1
    }
    if [ -f SHA256SUMS ]; then
        grep -E "^[0-9a-fA-F]{64} [ *]${arquivo//./\\.}$" SHA256SUMS | sha256sum --quiet -c -
    fi
    echo "Cargando $imaxe..."
    docker load -q -i "$arquivo" </dev/null
done < <("${COMPOSE[@]}" config --images)

# --remove-orphans: os contedores dos servizos anteriores ao 27-11-2026 (php-manual, devdocs e
# laravel-docs) volverían arrancar con Docker e ocuparían os portos. Este proxecto non ten perfís.
"${COMPOSE[@]}" up -d --no-build --pull never --remove-orphans --wait --wait-timeout 90

# Comproba os enderezos publicados unha vez que os contedores están listos.
porto() { "${COMPOSE[@]}" port "$1" "$2" | head -n 1 | sed 's/.*://'; }
declare -A URL=(
    [doc-php]="http://localhost:$(porto doc-php 80)/"
    [doc-web]="http://localhost:$(porto doc-web 9292)/"
    [doc-laravel]="http://localhost:$(porto doc-laravel 80)/"
)
fallos=0
for servizo in doc-php doc-web doc-laravel; do
    if curl -fsS --max-time 8 -o /dev/null "${URL[$servizo]}"; then
        echo "OK     $servizo en ${URL[$servizo]}"
    else
        echo "FALLA  $servizo non responde en ${URL[$servizo]}" >&2
        fallos=$((fallos + 1))
    fi
done
exit $((fallos > 0))
