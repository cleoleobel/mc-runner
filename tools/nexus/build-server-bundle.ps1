# ==============================================================================
# NEXUS SERVER BUNDLE BUILDER
# Empaquetador Automático de la Distribución Server-Side de NEXUS
# ==============================================================================

[CmdletBinding()]
param(
    [string]$Version = "2026.08.07-01",
    [string]$OutputDir = "dist/github"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   EMPAQUETADOR AUTOMATICO DE SERVIDOR NEXUS" -ForegroundColor Cyan
Write-Host "   Version Objetivo: $Version" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$WorkspaceRoot = Get-Location
$StagingDir = Join-Path $WorkspaceRoot "dist/staging_server"
$FinalOutputDir = Join-Path $WorkspaceRoot $OutputDir

# 1. Limpieza de staging previo
if (Test-Path $StagingDir) {
    Remove-Item -Recurse -Force $StagingDir
}
New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null
New-Item -ItemType Directory -Force -Path $FinalOutputDir | Out-Null

# 2. Verificación de archivos origen esenciales
$ServerReadyDir = Join-Path $WorkspaceRoot "dist/NEXUS_SERVER_READY"
$WorkServerDir = Join-Path $WorkspaceRoot "_work/server"

if (-not (Test-Path $ServerReadyDir)) {
    throw "ERROR CRITICO: No se encuentra $ServerReadyDir"
}

Write-Host "[1/8] Copiando mods de servidor desde NEXUS_SERVER_READY..." -ForegroundColor Yellow
$ModsStaging = New-Item -ItemType Directory -Force -Path (Join-Path $StagingDir "mods")

# Copiar mods aprobados para servidor
$ServerMods = Get-ChildItem -Path (Join-Path $ServerReadyDir "mods") -Filter "*.jar"
foreach ($mod in $ServerMods) {
    # Validar exclusiones prohibidas
    if ($mod.Name -match "IronsArms" -or $mod.Name -match "ArmsLib") {
        throw "PROHIBICION VIOLADA: Se detecto mod prohibido ($($mod.Name)). El empaquetador se aborta."
    }
    # Validar exclusiones de cliente
    if ($mod.Name -match "embeddium" -or $mod.Name -match "chloride" -or $mod.Name -match "entityculling" -or $mod.Name -match "immediatelyfast" -or $mod.Name -match "DistantHorizons" -or $mod.Name -match "Xaeros" -or $mod.Name -match "Controlling") {
        Write-Host "  [OMITIDO CLIENT-ONLY] $($mod.Name)" -ForegroundColor DarkGray
        continue
    }
    Copy-Item -Path $mod.FullName -Destination $ModsStaging.FullName -Force
    Write-Host "  [INCLUIDO] $($mod.Name)" -ForegroundColor Green
}

# Incluir optimizaciones server-side adicionales si existen en downloads
$DownloadsDir = Join-Path $WorkspaceRoot "downloads"
if (Test-Path $DownloadsDir) {
    $OptMods = Get-ChildItem -Path $DownloadsDir -Filter "*.jar" | Where-Object {
        $_.Name -match "Clumps" -or $_.Name -match "alternate_current" -or $_.Name -match "getittogetherdrops"
    }
    foreach ($opt in $OptMods) {
        Copy-Item -Path $opt.FullName -Destination $ModsStaging.FullName -Force
        Write-Host "  [INCLUIDO OPTIMIZADOR] $($opt.Name)" -ForegroundColor Green
    }
}

Write-Host "[2/8] Copiando configuraciones y voicechat..." -ForegroundColor Yellow
$ConfigStaging = New-Item -ItemType Directory -Force -Path (Join-Path $StagingDir "config")
if (Test-Path (Join-Path $ServerReadyDir "config")) {
    Copy-Item -Path (Join-Path $ServerReadyDir "config/*") -Destination $ConfigStaging.FullName -Recurse -Force
}
if (Test-Path (Join-Path $WorkspaceRoot "config/voicechat")) {
    $VoiceDir = New-Item -ItemType Directory -Force -Path (Join-Path $ConfigStaging.FullName "voicechat")
    Copy-Item -Path (Join-Path $WorkspaceRoot "config/voicechat/*") -Destination $VoiceDir.FullName -Recurse -Force
}

# Asegurar puerto UDP 24454 en voicechat-server.properties
$VoiceConfigFile = Join-Path $ConfigStaging.FullName "voicechat/voicechat-server.properties"
if (Test-Path $VoiceConfigFile) {
    $vContent = Get-Content -Path $VoiceConfigFile -Raw
    if ($vContent -match "port=") {
        $vContent = $vContent -replace "port=\d+", "port=24454"
    } else {
        $vContent += "`nport=24454`n"
    }
    Set-Content -Path $VoiceConfigFile -Value $vContent -Encoding UTF8
}

Write-Host "[3/8] Copiando TaCZ Gunpack y Datapacks..." -ForegroundColor Yellow
$TacZStaging = New-Item -ItemType Directory -Force -Path (Join-Path $StagingDir "tacz")
$GunpackSource = Join-Path $WorkspaceRoot "src/tacz/nexus_weapons"
if (Test-Path $GunpackSource) {
    $GunpackDest = New-Item -ItemType Directory -Force -Path (Join-Path $TacZStaging.FullName "nexus_weapons")
    Copy-Item -Path "$GunpackSource/*" -Destination $GunpackDest.FullName -Recurse -Force
    Write-Host "  [TACZ] Gunpack nexus_weapons copiado." -ForegroundColor Green
}

$DatapackSource = Join-Path $WorkspaceRoot "src/datapacks/nexus_progression"
$WorldDatapackDir = New-Item -ItemType Directory -Force -Path (Join-Path $StagingDir "defaultconfigs/datapacks/nexus_progression")
if (Test-Path $DatapackSource) {
    Copy-Item -Path "$DatapackSource/*" -Destination $WorldDatapackDir.FullName -Recurse -Force
    Write-Host "  [DATAPACK] nexus_progression copiado a defaultconfigs." -ForegroundColor Green
}

Write-Host "[4/8] Copiando estructura Forge y Librerias..." -ForegroundColor Yellow
if (Test-Path $WorkServerDir) {
    if (Test-Path (Join-Path $WorkServerDir "libraries")) {
        Copy-Item -Path (Join-Path $WorkServerDir "libraries") -Destination $StagingDir -Recurse -Force
    }
    if (Test-Path (Join-Path $WorkServerDir "run.sh")) {
        Copy-Item -Path (Join-Path $WorkServerDir "run.sh") -Destination $StagingDir -Force
    }
    if (Test-Path (Join-Path $WorkServerDir "user_jvm_args.txt")) {
        Copy-Item -Path (Join-Path $WorkServerDir "user_jvm_args.txt") -Destination $StagingDir -Force
    }
}

# Crear run.sh estándar de Forge si no se encontró
$RunShPath = Join-Path $StagingDir "run.sh"
if (-not (Test-Path $RunShPath)) {
    $RunShContent = '#!/usr/bin/env sh' + "`n" + 'java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.4.0/unix_args.txt "$@"' + "`n"
    Set-Content -Path $RunShPath -Value $RunShContent -Encoding UTF8
}

Write-Host "[5/8] Configurando server.properties y eula.txt..." -ForegroundColor Yellow
Set-Content -Path (Join-Path $StagingDir "eula.txt") -Value "eula=true" -Encoding UTF8

$ServerProps = @"
server-port=25565
enable-rcon=false
gamemode=survival
difficulty=hard
max-players=5
view-distance=8
simulation-distance=6
online-mode=true
allow-flight=true
motd=Servidor NEXUS Dedicated Forge 1.20.1
"@
Set-Content -Path (Join-Path $StagingDir "server.properties") -Value $ServerProps -Encoding UTF8

Write-Host "[6/8] Generando manifest.json..." -ForegroundColor Yellow
$ModFiles = Get-ChildItem -Path (Join-Path $StagingDir "mods") -Filter "*.jar"
$ManifestObj = [ordered]@{
    version = $Version
    minecraft = "1.20.1"
    forge = "47.4.0"
    java_required = 17
    created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    mods_count = $ModFiles.Count
    mod_list = ($ModFiles | Select-Object -ExpandProperty Name)
}
$ManifestJson = $ManifestObj | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $StagingDir "manifest.json") -Value $ManifestJson -Encoding UTF8
Set-Content -Path (Join-Path $FinalOutputDir "manifest.json") -Value $ManifestJson -Encoding UTF8

Write-Host "[7/8] Comprimiendo distribucion..." -ForegroundColor Yellow
$TarGzPath = Join-Path $FinalOutputDir "server-bundle.tar.gz"
if (Test-Path $TarGzPath) { Remove-Item -Force $TarGzPath }

Push-Location $StagingDir
try {
    tar -czf $TarGzPath .
} finally {
    Pop-Location
}

if (-not (Test-Path $TarGzPath)) {
    throw "ERROR CRITICO: No se pudo generar $TarGzPath"
}

Write-Host "[8/8] Calculando SHA-256 del bundle..." -ForegroundColor Yellow
$Hash = (Get-FileHash -Path $TarGzPath -Algorithm SHA256).Hash.ToLower()
$ChecksumContent = "$Hash  server-bundle.tar.gz`n"
Set-Content -Path (Join-Path $FinalOutputDir "checksums.sha256") -Value $ChecksumContent -Encoding UTF8

# Limpiar staging
Remove-Item -Recurse -Force $StagingDir

$ArchiveSizeMB = [math]::Round(((Get-Item $TarGzPath).Length / 1MB), 2)
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   BUNDLE CREADO EXITOSAMENTE" -ForegroundColor Green
Write-Host "   Archivo: $TarGzPath" -ForegroundColor Green
Write-Host "   Tamano: $ArchiveSizeMB MB" -ForegroundColor Green
Write-Host "   SHA-256: $Hash" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
