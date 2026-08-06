[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$WorldPath = "_work/test-world"
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================" -ForegroundColor Yellow
Write-Host "  DESINSTALADOR Y ROLLBACK MAESTRO - PROYECTO NEXUS  " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Yellow

$ResolvedWorldPath = Resolve-Path $WorldPath -ErrorAction SilentlyContinue
if (-not $ResolvedWorldPath -or -not (Test-Path (Join-Path $WorldPath "level.dat"))) {
    Write-Error "ERROR: Mundo no valido en '$WorldPath'."
    exit 1
}

$WorldDir = $ResolvedWorldPath.Path
$ManifestPath = Join-Path $WorldDir "nexus_installed_manifest.json"

if (-not (Test-Path $ManifestPath)) {
    Write-Host "ADVERTENCIA: No se encontro manifiesto de instalacion de NEXUS en este mundo." -ForegroundColor Red
    exit 1
}

$Manifest = Get-Content $ManifestPath | ConvertFrom-Json
$DatapackTargetDir = Join-Path $WorldDir $Manifest.InstalledDatapack

if (Test-Path $DatapackTargetDir) {
    Write-Host "Retirando datapack de progresion NEXUS..." -ForegroundColor Yellow
    Remove-Item -Path $DatapackTargetDir -Recurse -Force
}

Remove-Item -Path $ManifestPath -Force
Write-Host "DESINSTALACION COMPLETADA. Los archivos originales del mundo permanecen intactos." -ForegroundColor Green
Write-Host "Resguardo previo disponible en: $($Manifest.BackupZip) (SHA-256: $($Manifest.BackupSHA256))" -ForegroundColor Cyan
