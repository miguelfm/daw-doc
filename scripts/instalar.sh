#!/usr/bin/env bash
# Instala e arranca a documentación sen conexión, sen rede.
#
# Uso, no directorio do paquete (ou na raíz do proxecto):
#   ./instalar.sh            carga as imaxes que falten e arranca os servizos
#   ./instalar.sh estado     amosa os contedores
#   ./instalar.sh parar      para os contedores, sen borrar as imaxes
#
# As imaxes cárganse de daw-doc-imaxes.tar.gz despois de comprobar o seu
# SHA256. Os contedores levan restart: unless-stopped, e volven arrancar
# cada vez que arranca Docker.
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

faltan=()
while read -r imaxe; do
    docker image inspect "$imaxe" >/dev/null 2>&1 || faltan+=("$imaxe")
done < <("${COMPOSE[@]}" config --images)

if [ ${#faltan[@]} -gt 0 ]; then
    [ -f daw-doc-imaxes.tar.gz ] || {
        echo "Faltan ${faltan[*]} e non está daw-doc-imaxes.tar.gz." >&2
        exit 1
    }
    if [ -f SHA256SUMS ]; then
        sha256sum --quiet -c SHA256SUMS
    fi
    echo "Cargando as imaxes..."
    docker load -q -i daw-doc-imaxes.tar.gz
fi

"${COMPOSE[@]}" up -d --no-build

# Os servizos tardan uns segundos en responder
porto() { "${COMPOSE[@]}" port "$1" "$2" | sed 's/.*://'; }
declare -A URL=(
    [php-manual]="http://localhost:$(porto php-manual 80)/"
    [devdocs]="http://localhost:$(porto devdocs 9292)/"
    [laravel-docs]="http://localhost:$(porto laravel-docs 80)/"
)
fallos=0
for servizo in php-manual devdocs laravel-docs; do
    for _ in $(seq 30); do
        curl -s -o /dev/null "${URL[$servizo]}" && break
        sleep 1
    done
    if curl -s -o /dev/null "${URL[$servizo]}"; then
        echo "OK     $servizo en ${URL[$servizo]}"
    else
        echo "FALLA  $servizo non responde en ${URL[$servizo]}" >&2
        fallos=$((fallos + 1))
    fi
done
exit $((fallos > 0))
