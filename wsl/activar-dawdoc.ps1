#requires -Version 5.1
<#
.SYNOPSIS
Activa a documentación sen conexión na distribución de WSL desta conta.

.DESCRIPTION
Executa instalar.sh, que está no mesmo directorio ca este script, dentro da
distribución Debian-DAW, como o usuario ad: carga as imaxes do paquete en
Docker se faltan e arranca os servizos. Despois quedan en
http://localhost:8080/ (manual de PHP), http://localhost:5042/ (DevDocs) e
http://localhost:8088/ (Laravel), e volven arrancar con Docker. Non precisa
administración nin Internet, e repetilo é seguro.

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File C:\DAW-Doc\activar-dawdoc.ps1
#>
[CmdletBinding()]
param(
    [string]$Distribution = 'Debian-DAW',
    [string]$LinuxUser = 'ad'
)
$ErrorActionPreference = 'Stop'

$distros = (& wsl.exe --list --quiet) -replace "`0", '' | ForEach-Object { $_.Trim() }
if ($distros -notcontains $Distribution) {
    throw "Non está a distribución $Distribution nesta conta: activa antes DAW Dev."
}

# wsl.exe --cd acepta unha ruta absoluta de Windows
& wsl.exe -d $Distribution -u $LinuxUser --cd $PSScriptRoot --exec bash ./instalar.sh
$estado = $LASTEXITCODE
if ($estado -eq 0) {
    Write-Host 'A documentación está activada.'
} else {
    Write-Host "A activación rematou co código $estado." -ForegroundColor Red
}
exit $estado
