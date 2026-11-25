#!/usr/bin/env bash
# Para os contedores da documentación sen conexión (php-manual, devdocs, laravel-docs).
#
# Uso no paquete (na copia Git, executa scripts/parar.sh):
#   ./parar.sh
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ${AQUI##*/} == scripts && ! -f "$AQUI/compose.yaml" ]]; then
    AQUI="$(cd "$AQUI/.." && pwd)"
fi
cd "$AQUI"
COMPOSE=(docker compose -f "$AQUI/compose.yaml")

echo "Parando os contedores da documentación sen conexión..."
"${COMPOSE[@]}" stop "$@"
