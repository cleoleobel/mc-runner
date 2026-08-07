# ==============================================================================
# NEXUS SERVER BUNDLE PUBLISHER
# Publica el Server Bundle en GitHub Releases del Repositorio Privado NEXUS STORAGE
# ==============================================================================

[CmdletBinding()]
param(
    [string]$Version = "2026.08.07-01",
    [string]$StorageRepo = "cleoleobel/nexus-storage"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   PUBLICADOR DE BUNDLE DE SERVIDOR NEXUS" -ForegroundColor Cyan
Write-Host "   Target Repo: $StorageRepo" -ForegroundColor Cyan
Write-Host "   Version Tag: server-bundle-latest" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Ejecutar empaquetador local
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuilderPath = Join-Path $ScriptDir "build-server-bundle.ps1"

Write-Host "[1/4] Ejecutando empaquetador local..." -ForegroundColor Yellow
& $BuilderPath -Version $Version -OutputDir "dist/github"

# 2. Verificar archivos generados
$BundleFile = "dist/github/server-bundle.tar.gz"
$ManifestFile = "dist/github/manifest.json"
$ChecksumFile = "dist/github/checksums.sha256"

if (-not (Test-Path $BundleFile) -or -not (Test-Path $ManifestFile) -or -not (Test-Path $ChecksumFile)) {
    throw "ERROR: Archivos de bundle incompletos en dist/github"
}

# 3. Verificar estado de GitHub CLI
Write-Host "[2/4] Verificando autenticacion de GitHub CLI..." -ForegroundColor Yellow
try {
    gh auth status | Out-Null
} catch {
    throw "ERROR: gh CLI no esta autenticado. Ejecuta 'gh auth login' primero."
}

# 4. Publicar / Actualizar Release en GitHub Storage
Write-Host "[3/4] Creando/Actualizando release 'server-bundle-latest' en $StorageRepo..." -ForegroundColor Yellow
$Title = "NEXUS Server Bundle v$Version"
$Notes = "Release oficial de distribución server-side para NEXUS Java 1.20.1 Forge 47.4.0."

# Comprobar si la release ya existe (manejando NativeCommandError en PowerShell)
$ReleaseExists = $false
$OldErrorPref = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    $viewOutput = gh release view server-bundle-latest --repo $StorageRepo 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ReleaseExists = $true
    }
} catch {
    $ReleaseExists = $false
} finally {
    $ErrorActionPreference = $OldErrorPref
}

if ($ReleaseExists) {
    Write-Host "  -> Release existe. Subiendo assets actualizados..." -ForegroundColor Yellow
    gh release upload server-bundle-latest $BundleFile $ManifestFile $ChecksumFile --repo $StorageRepo --clobber
} else {
    Write-Host "  -> Creando nueva release 'server-bundle-latest'..." -ForegroundColor Yellow
    gh release create server-bundle-latest $BundleFile $ManifestFile $ChecksumFile --repo $StorageRepo --title $Title --notes $Notes --latest
}

if ($LASTEXITCODE -ne 0) {
    throw "ERROR CRITICO: Fallo al publicar release en GitHub."
}

Write-Host "==================================================" -ForegroundColor Green
Write-Host "   BUNDLE PUBLICADO CORRECTAMENTE EN GITHUB" -ForegroundColor Green
Write-Host "   Repositorio: $StorageRepo" -ForegroundColor Green
Write-Host "   Tag Release: server-bundle-latest" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
