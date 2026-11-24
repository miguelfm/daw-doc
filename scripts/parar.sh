#!/usr/bin/env bash
# Para os contedores da documentación sen conexión (php-manual, devdocs, laravel-docs).
#
# Uso, no directorio do paquete (ou na raíz do proxecto):
#   ./parar.sh
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$AQUI"
COMPOSE=(docker compose -f "$AQUI/compose.yaml")

echo "Parando os contedores da documentación sen conexión..."
"${COMPOSE[@]}" stop "$@"
