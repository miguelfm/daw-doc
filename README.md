# daw-doc

Documentación técnica sen conexión para as aulas de Desenvolvemento de
Aplicacións Web: tres servizos de Docker con buscador, pensados para os exames
e para as aulas sen Internet.

| Servizo | Enderezo | Contido |
|---|---|---|
| `php-manual` | <http://localhost:8080/> | Manual oficial de PHP en inglés, co buscador Pagefind |
| `devdocs` | <http://localhost:5042/> | DevDocs con HTML e CSS |
| `laravel-docs` | <http://localhost:8088/> | Documentación de Laravel 12.x, co buscador lunr.js |

É autónomo: non depende de `daw-dev`, aínda que nas aulas se instala na mesma
distribución de WSL, `Debian-DAW`, e co mesmo Docker. Os portos son os da
documentación da MV de `daw-vm`, de onde veñen os tres `Dockerfile`.

## Construír o paquete

As imaxes constrúense unha vez, nun equipo con Internet, e gárdanse nun
paquete que se instala despois sen rede:

```bash
scripts/empaquetar.sh            # deixa o paquete en dist/
```

| Ficheiro | Contido |
|---|---|
| `daw-doc-imaxes.tar.gz` | As tres imaxes, gardadas con `docker save` (uns 66 MB) |
| `SHA256SUMS` | O resumo do ficheiro anterior |
| `compose.yaml` | O do proxecto |
| `instalar.sh` | Carga as imaxes que falten e arranca os servizos |
| `activar-dawdoc.ps1` | O mesmo desde Windows, na distribución de WSL da conta |

Para cambiar o idioma do manual, as linguaxes de DevDocs ou a versión de
Laravel, `PHP_MANUAL_LANG`, `DEVDOCS_LANGS` e `LARAVEL_VERSION` nun `.env`.

## Instalar

En Linux, ou dentro da distribución de WSL, no directorio do paquete:

```bash
./instalar.sh            # carga as imaxes se faltan e arranca os servizos
./instalar.sh estado     # os contedores
./instalar.sh parar      # párase, sen borrar as imaxes
```

O script comproba o SHA256 antes de cargar as imaxes e espera a que respondan
os tres enderezos. Os contedores levan `restart: unless-stopped`, e volven
arrancar cada vez que arranca Docker. Repetilo é seguro.

## Nas aulas

A distribución de WSL e o seu Docker son de cada conta de Windows, e por iso a
documentación se activa unha vez en cada conta, despois de activar DAW Dev:

1. No equipo do docente, como administrador dos equipos, `wsl/aula/copiar-paquete.ps1`
   copia o paquete por WinRM a `C:\DAW-Doc` de cada equipo, comproba o SHA256 e
   crea no menú Inicio de todos os usuarios o acceso directo
   *DAW Dev → DAW Doc - Activar documentación*:

   ```powershell
   .\wsl\aula\copiar-paquete.ps1 -ComputerName A34EQ01,A34EQ02 -Package C:\DAW-Doc-Paquete
   ```

2. Cada persoa abre o acceso directo, que executa `activar-dawdoc.ps1`: este
   lanza `instalar.sh` en `Debian-DAW` como `ad`, sen administración nin
   Internet.

## Estado

- Comprobado o 24-11-2026 en Linux, con Docker 29: a construción, o paquete,
  a instalación sen as imaxes, que as carga e arranca os tres servizos, a
  repetición, que non carga nada, e un `SHA256SUMS` alterado, que detén a
  instalación.
- Os scripts de Windows só se analizaron con PowerShell 7. Faltan por probar
  con Windows PowerShell 5.1, WinRM e WSL nun equipo da aula.
- O `Dockerfile` de DevDocs de `daw-vm` non se constrúe co analizador actual de
  Docker, por un `python3 -c` de varias liñas; aquí ese código vai en
  `devdocs/desempaquetar.py`.
