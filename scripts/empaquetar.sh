#!/usr/bin/env bash
# Constrúe as imaxes da documentación e prepara o paquete para instalar
# sen rede.
#
# Uso, desde a raíz do proxecto e con conexión a Internet:
#   scripts/empaquetar.sh [DIRECTORIO]
#
# Deixa en DIRECTORIO (por defecto dist/):
#   daw-doc-imaxes.tar.gz   as tres imaxes, gardadas con docker save
#   SHA256SUMS              o resumo do ficheiro anterior
#   compose.yaml            o do proxecto
#   instalar.sh             o script que carga as imaxes e as arranca
#   activar-dawdoc.ps1      o mesmo desde Windows, na distribución de WSL
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAIDA="${1:-$RAIZ/dist}"
cd "$RAIZ"

docker compose build
mapfile -t IMAXES < <(docker compose config --images)
mkdir -p "$SAIDA"
echo "Gardando ${IMAXES[*]}"
docker save "${IMAXES[@]}" | gzip -6 > "$SAIDA/daw-doc-imaxes.tar.gz"
(cd "$SAIDA" && sha256sum daw-doc-imaxes.tar.gz > SHA256SUMS)
cp compose.yaml scripts/instalar.sh wsl/activar-dawdoc.ps1 "$SAIDA/"
chmod +x "$SAIDA/instalar.sh"
ls -l "$SAIDA"
