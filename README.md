# daw-doc

Documentación técnica sen conexión para as aulas de Desenvolvemento de
Aplicacións Web: tres servizos de Docker con buscador, pensados para os exames
e para as clases sen Internet.

| Servizo | Enderezo | Contido |
|---|---|---|
| `php-manual` | <http://localhost:8080/> | Manual oficial de PHP en inglés, co buscador Pagefind |
| `devdocs` | <http://localhost:5042/> | DevDocs con HTML e CSS |
| `laravel-docs` | <http://localhost:8088/> | Documentación de Laravel 12.x, co buscador lunr.js |

É autónomo: funciona só con Docker. [DAW Dev](https://github.com/miguelfm/daw-dev)
usa as mesmas imaxes e portos no seu perfil `doc`, coa orde `daw-start-doc`. Os
`Dockerfile` veñen da documentación sen conexión da MV da aula.

## Construír as imaxes

As imaxes constrúense unha vez, nun equipo con Internet, e gárdanse para
instalalas despois sen rede:

```bash
scripts/empaquetar.sh            # deixa o paquete en dist/
```

| Ficheiro | Contido |
|---|---|
| `daw-doc-php.tar.gz`, `daw-doc-devdocs.tar.gz`, `daw-doc-laravel.tar.gz` | Cada imaxe, gardada con `docker save` (uns 115 MB entre as tres) |
| `SHA256SUMS` | Os resumos dos tres arquivos |
| `compose.yaml` | O do proxecto |
| `instalar.sh` | Carga as imaxes que falten e arranca os servizos |

Cada arquivo leva unha soa imaxe, como os rexistra o paquete da aula de DAW Dev.
Para cambiar o idioma do manual, as linguaxes de DevDocs ou a versión de
Laravel, `PHP_MANUAL_LANG`, `DEVDOCS_LANGS` e `LARAVEL_VERSION` nun `.env`.

## Usar sen DAW Dev

En Linux, no directorio do paquete:

```bash
./instalar.sh            # carga as imaxes que falten e arranca os servizos
./instalar.sh estado     # os contedores
./instalar.sh parar      # párase, sen borrar as imaxes
```

O script comproba o SHA256 de cada arquivo antes de cargalo e espera a que
respondan os tres enderezos. Os contedores levan `restart: unless-stopped`, e
volven arrancar cada vez que arranca Docker. Repetilo é seguro. Desde a raíz do
proxecto, `docker compose up -d` fai o mesmo coas imaxes xa construídas.

## Nas aulas, con DAW Dev

As aulas usan a infraestrutura de DAW Dev: o paquete que se copia por WinRM aos
equipos, a Debian de WSL de cada conta e o seu Docker. Os tres arquivos
engádense a ese paquete con `engadir-imaxe.ps1`, e `daw-start-doc` cárgaos a
primeira vez en cada conta. O procedemento está na
[guía de despregamento de DAW Dev](https://github.com/miguelfm/daw-dev/blob/main/docs/aula-windows11.md#documentación-sen-conexión-daw-doc).

Na Debian de WSL, `instalar.sh` non basta: WSL pecha a distribución cando
non queda ningún proceso aberto, e os contedores páranse con ela. DAW Dev
mantena aberta mentres hai servizos en marcha.

Nun equipo con DAW Dev, `daw-start-doc` substitúe a `instalar.sh`. Os dous usan
os mesmos portos: antes de `daw-start-doc`, `./instalar.sh parar`, e antes de
`instalar.sh`, `daw-stop`.

## Licenzas

O código deste repositorio ten licenza MIT. As imaxes levan contido doutros
proxectos, coas súas licenzas: o manual de PHP (CC BY 3.0), DevDocs (MPL 2.0) e
os documentos de MDN que inclúe (CC BY-SA 2.5 ou posterior), e a documentación de Laravel
(MIT).

## Estado

- Comprobado o 24-11-2026 en Linux, con Docker 29 e Compose 5.8:
  - a construción e o paquete;
  - a instalación sen as imaxes, que as carga e arranca os tres servizos `healthy`;
  - a repetición, que non carga nada, e un resumo alterado, que detén a carga desa imaxe;
  - `daw-start-doc` e `daw-stop` de DAW Dev en Linux, e `instalar.sh` no mesmo
    equipo, cos contedores de DAW Dev parados.
- Falta probar `daw-start-doc` nun equipo Windows da aula, coas imaxes do paquete.
- O `Dockerfile` de DevDocs da MV non se constrúe co analizador actual de
  Docker, por un `python3 -c` de varias liñas; aquí ese código vai en
  `devdocs/desempaquetar.py`.
