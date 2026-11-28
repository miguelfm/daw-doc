# daw-doc

Documentación técnica sen conexión para as aulas de Desenvolvemento de
Aplicacións Web: tres servizos de Docker con buscador, pensados para os exames
e para as clases sen Internet.

| Servizo | Enderezo | Contido |
|---|---|---|
| `doc-php` | <http://localhost:8080/> | Manual oficial de PHP en inglés, co buscador Pagefind |
| `doc-web` | <http://localhost:5042/> | Referencia web: HTML, HTTP e CSS de MDN Web Docs, en inglés, cos datos de DevDocs e o buscador Pagefind |
| `doc-laravel` | <http://localhost:8088/> | Documentación de Laravel 13.x, co buscador lunr.js |

É autónomo: funciona só con Docker. [DAW Dev](https://github.com/miguelfm/daw-dev)
usa as mesmas imaxes, servizos e portos no seu perfil `doc`, coa orde `daw-start-doc`.
Os servizos levan o nome do seu papel (`doc-php`, `doc-web`, `doc-laravel`), que é tamén o
hostname; ata o 27-11-2026 eran `php-manual`, `devdocs` e `laravel-docs`, e `instalar.sh` retira
os seus contedores. As variables `DOC_PHP_PORT`, `DOC_WEB_PORT` e `DOC_LARAVEL_PORT` substitúen a
`PHP_MANUAL_PORT`, `DEVDOCS_PORT` e `LARAVEL_DOCS_PORT`, que seguen funcionando. Os
`Dockerfile` veñen da documentación sen conexión da MV da aula.

## Construír as imaxes

Constrúe as imaxes nun equipo con Internet e gárdaas para instalalas despois
sen rede. Para actualizar un paquete existente, actualiza o repositorio e
volve executar o mesmo comando:

```bash
scripts/empaquetar.sh            # deixa o paquete en dist/
```

O script descarga as imaxes base actuais e volve obter o manual de PHP,
os datos de DevDocs e a documentación de Laravel 13.x. A construción usa
Node.js 26 para Pagefind (e Python para xerar as páxinas de DevDocs) e Python
3.15 para xerar o sitio de Laravel con MkDocs e Material.

| Ficheiro | Contido |
|---|---|
| `daw-doc-php.tar.gz`, `daw-doc-devdocs.tar.gz`, `daw-doc-laravel.tar.gz` | Cada imaxe, gardada con `docker save` (arredor de 125 MB entre as tres) |
| `SHA256SUMS` | Os resumos dos tres arquivos |
| `compose.yaml` | O do proxecto |
| `instalar.sh` | Carga as imaxes que falten e arranca os servizos |
| `parar.sh` | Para os contedores da documentación |

Cada arquivo leva unha soa imaxe, como os rexistra o paquete da aula de DAW Dev.
Para cambiar o idioma do manual, as documentacións de DevDocs ou a versión de
Laravel, `PHP_MANUAL_LANG`, `DEVDOCS_LANGS` e `LARAVEL_VERSION` nun `.env`.

## Publicar en GHCR e releases

GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) constrúe as tres imaxes,
compróbaas con `scripts/verificar.sh` e publícaas en GHCR (`ghcr.io/miguelfm/daw-doc-php:en`,
`ghcr.io/miguelfm/daw-doc-devdocs:latest` e `ghcr.io/miguelfm/daw-doc-laravel:13.x`) en cada cambio
de `main` e o día 1 de cada mes. Así, en Linux/macOS con conexión a Internet, `daw-start-doc`
descárgaas directamente con `docker pull`.

Ademais, ao crear unha etiqueta `docs-AAAA-MM-DD` (ou lanzar o workflow con `publish_release=true`),
a CI xera e publica os arquivos `.tar.gz` e `SHA256SUMS` como release de GitHub para o paquete
sen conexión da aula (`windows\classroom\add-doc-images.ps1` en DAW Dev).

Se prefires publicar unha release desde local despois de `scripts/empaquetar.sh` e de facer commit dos cambios:

```bash
(cd dist && sha256sum -c SHA256SUMS)
gh release create docs-$(date +%F) dist/*.tar.gz dist/SHA256SUMS --target "$(git rev-parse HEAD)" \
    --title "Documentación sen conexión $(date +%F)" --notes "Construída desde $(git rev-parse --short HEAD)."
```

Cada arquivo debe ocupar menos de 2 GiB. As releases antigas pódense borrar con
`gh release delete <tag> --cleanup-tag`.

## Referencia web (`doc-web`)

Non é a aplicación de DevDocs: esta só funciona servida desde devdocs.io e, fóra
del, avisa de que está noutro sitio e descarga os documentos de Internet.
`devdocs/build-site.py` descarga de `documents.devdocs.io` o índice e as páxinas
de cada documentación de `DEVDOCS_LANGS` (por defecto `html http css`), o contido de
MDN Web Docs en inglés que prepara DevDocs, e garda cada páxina como HTML estático.
Cada documentación ten unha portada coas súas entradas por tipo, e a portada do
sitio, a busca de Pagefind en todas elas. Non se carga nada de Internet.

Para engadir outra, engade o seu *slug* de <https://devdocs.io/docs/docs.json>
(por exemplo, `javascript` ou `dom`) a `DEVDOCS_LANGS` e volve construír.

## Usar sen DAW Dev

En Linux, no directorio do paquete, executa:

```bash
./instalar.sh            # carga as imaxes que falten e arranca os servizos
./instalar.sh estado     # os contedores
./parar.sh               # para os contedores (ou ./instalar.sh parar)
```

O script comproba o SHA256 de cada arquivo antes de cargalo e espera a que
respondan os tres enderezos. Os contedores levan `restart: unless-stopped`, e
volven arrancar cada vez que arranca Docker. Para instalar un paquete novo
nun Docker que xa ten etiquetas anteriores, comproba `sha256sum -c SHA256SUMS`
e carga os tres arquivos con `docker load -i <arquivo>` antes de executar
`./instalar.sh`.

Desde unha copia Git, constrúe primeiro as imaxes e usa os scripts da carpeta
`scripts/`:

```bash
docker compose build --pull --no-cache
bash scripts/instalar.sh
bash scripts/instalar.sh estado
bash scripts/parar.sh
```

## Nas aulas, con DAW Dev

As aulas usan a infraestrutura de DAW Dev: o paquete que se copia por WinRM aos
equipos, a Debian de WSL de cada conta e o seu Docker. Os tres arquivos
engádense a ese paquete con `add-doc-images.ps1` (ou `add-package-image.ps1` desde arquivos locais),
e `daw-start-doc` cárgaos a primeira vez en cada conta. O procedemento está na
[guía de despregamento de DAW Dev](https://github.com/miguelfm/daw-dev/blob/main/docs/aula-windows11.md#documentación-sen-conexión-daw-doc).

Na Debian de WSL, `instalar.sh` non basta: WSL pecha a distribución cando
non queda ningún proceso aberto, e os contedores páranse con ela. DAW Dev
mantena aberta mentres hai servizos en marcha.

Nun equipo con DAW Dev, usa `daw-start-doc` e `daw-stop-doc`. Nunha instalación
manual, constrúe ou carga as imaxes no mesmo Docker de Debian que usa DAW Dev.
Se preparas un paquete para a aula, distribúe os tres arquivos e o manifesto
actualizado. Para cambiar entre o paquete autónomo e DAW Dev, detén primeiro
os servizos de documentación que están en marcha, pois comparten os portos.

## Licenzas

O código deste repositorio ten licenza MIT. As imaxes levan contido doutros
proxectos, coas súas licenzas: o manual de PHP (CC BY 3.0), os documentos de MDN
Web Docs preparados por DevDocs (CC BY-SA 2.5 ou posterior), e a documentación de Laravel
(MIT).

## Estado

- Comprobado o 24-11-2026 en Linux, con Docker 29 e Compose 5.8:
  - a construción e o paquete;
  - a instalación sen as imaxes, que as carga e arranca os tres servizos `healthy`;
  - a repetición, que non carga nada, e un resumo alterado, que detén a carga desa imaxe;
  - `daw-start-doc` e `daw-stop` de DAW Dev en Linux, e `instalar.sh` no mesmo
    equipo, cos contedores de DAW Dev parados.
- Comprobado en Windows 11 nunha distribución WSL de proba co modelo da aula.
  `daw-start-doc` cargou os tres arquivos do paquete e os recursos de busca
  responderon nos tres servizos. `daw-stop-doc` conservou o servidor web en marcha.
- Desde o 26-11-2026, a referencia web é un sitio estático (véxase *Referencia web*). A
  copia anterior da aplicación de devdocs.io descargaba os documentos de
  Internet e avisaba de que non estaba en devdocs.io. Comprobado en Linux con
  HTML, HTTP e CSS (1659 páxinas): resolven todas as ligazóns internas salvo seis
  da páxina `grid` a alias antigos que DevDocs non inclúe (`grid-column-gap` e
  `grid-row-gap`), ningunha páxina carga recursos externos e a busca atopa as
  páxinas esperadas cun navegador sen acceso a Internet.
