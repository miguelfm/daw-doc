#!/usr/bin/env bash
# Constrúe as imaxes da documentación e prepara o paquete para instalar
# sen rede.
#
# Uso, desde a raíz do proxecto e con conexión a Internet:
#   scripts/empaquetar.sh [DIRECTORIO]
#
# Deixa en DIRECTORIO (por defecto dist/):
#   daw-doc-php.tar.gz       cada imaxe, gardada con docker save
#   daw-doc-devdocs.tar.gz
#   daw-doc-laravel.tar.gz
#   SHA256SUMS               os resumos dos tres ficheiros anteriores
#   compose.yaml             o do proxecto
#   instalar.sh              o script que carga as imaxes e as arranca
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAIDA="${1:-$RAIZ/dist}"
cd "$RAIZ"

docker compose build
mkdir -p "$SAIDA"
arquivos=()
for servizo in php-manual devdocs laravel-docs; do
    imaxe=$(docker compose config --images "$servizo")
    # daw-doc-php, daw-doc-devdocs, daw-doc-laravel
    arquivo="$(basename "${imaxe%%:*}").tar.gz"
    echo "Gardando $imaxe en $arquivo"
    docker save "$imaxe" | gzip -6 > "$SAIDA/$arquivo"
    arquivos+=("$arquivo")
done
(cd "$SAIDA" && sha256sum "${arquivos[@]}" > SHA256SUMS)
cp compose.yaml scripts/instalar.sh "$SAIDA/"
chmod +x "$SAIDA/instalar.sh"
ls -l "$SAIDA"
