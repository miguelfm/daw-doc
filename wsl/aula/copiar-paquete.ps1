#requires -Version 5.1
<#
.SYNOPSIS
Copia o paquete da documentación aos equipos dunha aula por WinRM e crea o
acceso directo para activala.

.DESCRIPTION
Desde o equipo do docente, como administrador dos equipos. En cada equipo,
copia o paquete (o directorio que deixa scripts/empaquetar.sh) a
$Destination, comproba o SHA256 das imaxes e crea no menú Inicio de todos
os usuarios o acceso directo «DAW Doc - Activar documentación», que
executa activar-dawdoc.ps1 na conta de quen o abre. Cada persoa actívaa
unha vez na súa conta, despois de activar DAW Dev, porque a distribución
de WSL e o seu Docker son de cada conta. Repetilo é seguro: substitúe o
paquete e o acceso directo.

.EXAMPLE
.\copiar-paquete.ps1 -ComputerName A34EQ01,A34EQ02 -Package C:\DAW-Doc-Paquete
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string[]]$ComputerName,
    [Parameter(Mandatory)][string]$Package,
    [string]$Destination = 'C:\DAW-Doc',
    [pscredential]$Credential
)
$ErrorActionPreference = 'Stop'

$ficheiros = 'daw-doc-imaxes.tar.gz', 'SHA256SUMS', 'compose.yaml',
    'instalar.sh', 'activar-dawdoc.ps1'
foreach ($f in $ficheiros) {
    if (-not (Test-Path -LiteralPath (Join-Path $Package $f))) {
        throw "Falta $f en ${Package}: xera o paquete con scripts/empaquetar.sh."
    }
}
$esperado = (((Get-Content -LiteralPath (Join-Path $Package 'SHA256SUMS')) -split '\s+')[0]).ToUpperInvariant()

$opcions = @{}
if ($Credential) { $opcions.Credential = $Credential }
$resultados = foreach ($equipo in $ComputerName) {
    if (-not $PSCmdlet.ShouldProcess($equipo, "Copiar o paquete a $Destination")) {
        continue
    }
    try {
        $sesion = New-PSSession -ComputerName $equipo @opcions
        try {
            Invoke-Command -Session $sesion -ScriptBlock {
                New-Item -ItemType Directory -Force -Path $using:Destination | Out-Null
            }
            foreach ($f in $ficheiros) {
                Copy-Item -ToSession $sesion -LiteralPath (Join-Path $Package $f) `
                    -Destination (Join-Path $Destination $f) -Force
            }
            Invoke-Command -Session $sesion -ScriptBlock {
                $tar = Join-Path $using:Destination 'daw-doc-imaxes.tar.gz'
                $hash = (Get-FileHash -LiteralPath $tar -Algorithm SHA256).Hash
                if ($hash -ne $using:esperado) {
                    throw "O SHA256 de $tar non coincide."
                }
                # Acceso directo para todos os usuarios
                $menu = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\DAW Dev'
                New-Item -ItemType Directory -Force -Path $menu | Out-Null
                $shell = New-Object -ComObject WScript.Shell
                $acceso = $shell.CreateShortcut((Join-Path $menu 'DAW Doc - Activar documentación.lnk'))
                $acceso.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
                $acceso.Arguments = '-NoProfile -ExecutionPolicy Bypass -NoExit -File "' +
                    (Join-Path $using:Destination 'activar-dawdoc.ps1') + '"'
                $acceso.WorkingDirectory = $using:Destination
                $acceso.Save()
            }
            [pscustomobject]@{ Equipo = $equipo; Estado = 'Copiado' }
        } finally {
            Remove-PSSession $sesion
        }
    } catch {
        [pscustomobject]@{ Equipo = $equipo; Estado = "Erro: $($_.Exception.Message)" }
    }
}
$resultados | Format-Table -AutoSize
