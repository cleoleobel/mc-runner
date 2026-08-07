# ==============================================================================
# NEXUS AUTOMATED SETUP HELPER
# Configura el Repositorio de Almacenamiento, Empaqueta y Publica el Server Bundle
# ==============================================================================

[CmdletBinding()]
param(
    [string]$Owner = "cleoleobel",
    [string]$StorageRepoName = "nexus-storage",
    [string]$RunnerRepoName = "mc-runner"
)

$ErrorActionPreference = "Stop"

$StorageRepo = "$Owner/$StorageRepoName"
$RunnerRepo = "$Owner/$RunnerRepoName"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   CONFIGURADOR AUTOMATICO DE INFRAESTRUCTURA NEXUS" -ForegroundColor Cyan
Write-Host "   Storage Repo: $StorageRepo" -ForegroundColor Cyan
Write-Host "   Runner Repo:  $RunnerRepo" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Comprobar GitHub CLI
Write-Host "[1/4] Comprobando autenticacion en GitHub CLI..." -ForegroundColor Yellow
try {
    gh auth status
} catch {
    throw "ERROR: Debe estar autenticado en GitHub CLI. Ejecute 'gh auth login' antes de continuar."
}

# 2. Comprobar o Crear Repositorio de Almacenamiento Privado
Write-Host "[2/4] Verificando repositorio privado $StorageRepo..." -ForegroundColor Yellow
$RepoExists = $false
try {
    gh repo view $StorageRepo | Out-Null
    $RepoExists = $true
    Write-Host "  -> Repositorio $StorageRepo ya existe." -ForegroundColor Green
} catch {
    Write-Host "  -> El repositorio no existe. Creando $StorageRepo como PRIVADO..." -ForegroundColor Yellow
    gh repo create $StorageRepo --private --description "NEXUS Server Storage (Bundles y backups de mundo)"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  -> Repositorio $StorageRepo creado exitosamente." -ForegroundColor Green
    } else {
        throw "ERROR: No se pudo crear el repositorio $StorageRepo."
    }
}

# 3. Empaquetar y Publicar Bundle Inicial
Write-Host "[3/4] Empaquetando y publicando Bundle de Servidor en $StorageRepo..." -ForegroundColor Yellow
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PublisherPath = Join-Path $ScriptDir "publish-server-bundle.ps1"

& $PublisherPath -Version "2026.08.07-01" -StorageRepo $StorageRepo

# 4. Resumen de Instrucciones Finales
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   CONFIGURACION AUTOMATICA COMPLETADA" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "REPOSITORIOS LISTOS:" -ForegroundColor Yellow
Write-Host "  - Storage (Privado): https://github.com/$StorageRepo" -ForegroundColor White
Write-Host "  - Runner  (Publico): https://github.com/$RunnerRepo" -ForegroundColor White
Write-Host ""
Write-Host "PASOS UNICOS RESTANTES EN GITHUB:" -ForegroundColor Yellow
Write-Host "1. En GitHub ($RunnerRepo > Settings > Secrets and variables > Actions > Secrets):" -ForegroundColor White
Write-Host "   - Crea el secreto 'NEXUS_STORAGE_TOKEN' (PAT Fine-Grained con permiso Contents: Write en $StorageRepo)" -ForegroundColor White
Write-Host "   - Crea el secreto 'PLAYIT_SECRET' (Secret key del agente Playit.gg)" -ForegroundColor White
Write-Host "2. En Playit.gg (https://playit.gg):" -ForegroundColor White
Write-Host "   - Crea un tunel Custom: TCP -> 25565 (Minecraft Java)" -ForegroundColor White
Write-Host "   - Crea un tunel Custom: UDP -> 24454 (Simple Voice Chat)" -ForegroundColor White
Write-Host "3. Ir a https://github.com/$RunnerRepo/actions -> Workflow NEXUS Java Server -> Run workflow" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Green
