# ==============================================================================
# NEXUS SERVER BUNDLE BUILDER
# Empaquetador Automático de la Distribución Server-Side de NEXUS
# ==============================================================================

[CmdletBinding()]
param(
    [string]$Version = "2026.08.07-01",
    [string]$OutputDir = "dist/github",
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   EMPAQUETADOR AUTOMATICO DE SERVIDOR NEXUS" -ForegroundColor Cyan
Write-Host "   Version Objetivo: $Version" -ForegroundColor Cyan
Write-Host "   Modo DryRun:     $DryRun" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$WorkspaceRoot = Get-Location
$StagingDir = Join-Path $WorkspaceRoot "dist/staging_server"
$FinalOutputDir = Join-Path $WorkspaceRoot $OutputDir

# Buscar fuente principal de mods: Instancia activa local primero, fallback a dist/NEXUS_SERVER_READY
$ClientInstanceMods = "C:\Users\PC\AppData\Roaming\.minecraft\instances\f094d86375724af2bd72f8fffd725379\mods"
$ServerReadyDir = Join-Path $WorkspaceRoot "dist/NEXUS_SERVER_READY"
$WorkServerDir = Join-Path $WorkspaceRoot "_work/server"

$ModSourceDir = $null
if (Test-Path $ClientInstanceMods) {
    $ModSourceDir = $ClientInstanceMods
    Write-Host "[MOD SOURCE] Usando instancia cliente local activa: $ModSourceDir" -ForegroundColor Green
} elseif (Test-Path (Join-Path $ServerReadyDir "mods")) {
    $ModSourceDir = Join-Path $ServerReadyDir "mods"
    Write-Host "[MOD SOURCE] Usando NEXUS_SERVER_READY: $ModSourceDir" -ForegroundColor Yellow
} else {
    throw "ERROR CRITICO: No se encontró fuente de mods válida."
}

if (-not $DryRun) {
    if (Test-Path $StagingDir) { Remove-Item -Recurse -Force $StagingDir }
    New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null
    New-Item -ItemType Directory -Force -Path $FinalOutputDir | Out-Null
}

Write-Host "[1/8] Clasificando y seleccionando mods de servidor..." -ForegroundColor Yellow
$ModsStaging = if (-not $DryRun) { New-Item -ItemType Directory -Force -Path (Join-Path $StagingDir "mods") } else { $null }

$SourceMods = Get-ChildItem -Path $ModSourceDir -Filter "*.jar"
$IncludedCount = 0
$ExcludedCount = 0

foreach ($mod in $SourceMods) {
    # Validar exclusiones prohibidas (IronsArms / ArmsLib)
    if ($mod.Name -match "IronsArms" -or $mod.Name -match "ArmsLib") {
        throw "PROHIBICION VIOLADA: Se detecto mod prohibido ($($mod.Name)). El empaquetador se aborta."
    }

    # Validar exclusiones de cliente
    if ($mod.Name -match "embeddium" -or $mod.Name -match "chloride" -or `
        $mod.Name -match "entityculling" -or $mod.Name -match "immediatelyfast" -or `
        $mod.Name -match "DistantHorizons" -or $mod.Name -match "xaero" -or `
        $mod.Name -match "Controlling" -or $mod.Name -match "vanillin" -or `
        $mod.Name -match "sodiumoptionsapi" -or $mod.Name -match "CullLessLeaves" -or `
        $mod.Name -match "gpumemleakfix" -or $mod.Name -match "Searchables") {
        Write-Host "  [OMITIDO CLIENT-ONLY] $($mod.Name)" -ForegroundColor DarkGray
        $ExcludedCount++
        continue
    }

    # Validar version de Cataclysm (asegurar v3.16 sobre v3.31 si existe)
    if ($mod.Name -match "Cataclysm" -and $mod.Name -notmatch "3.16" -and $mod.Name -notmatch "spellbooks") {
        Write-Host "  [OMITIDO VERSION INCOMPATIBLE] $($mod.Name) (Requiere Cataclysm 3.16)" -ForegroundColor Red
        $ExcludedCount++
        continue
    }

    Write-Host "  [INCLUIDO SERVER/BOTH] $($mod.Name)" -ForegroundColor Green
    $IncludedCount++
    if (-not $DryRun) {
        Copy-Item -Path $mod.FullName -Destination $ModsStaging.FullName -Force
    }
}

# Incluir optimizaciones server-side desde downloads si no estaban en el origen
$DownloadsDir = Join-Path $WorkspaceRoot "downloads"
if (Test-Path $DownloadsDir) {
    $OptMods = Get-ChildItem -Path $DownloadsDir -Filter "*.jar" | Where-Object {
        $_.Name -match "Clumps" -or $_.Name -match "alternate_current" -or $_.Name -match "getittogetherdrops"
    }
    foreach ($opt in $OptMods) {
        if (-not $DryRun -and -not (Test-Path (Join-Path $ModsStaging.FullName $opt.Name))) {
            Copy-Item -Path $opt.FullName -Destination $ModsStaging.FullName -Force
            Write-Host "  [INCLUIDO OPTIMIZADOR DOWNLOADS] $($opt.Name)" -ForegroundColor Green
            $IncludedCount++
        }
    }
}

if ($DryRun) {
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "   RESUMEN DRY-RUN:" -ForegroundColor Yellow
    Write-Host "   Mods Incluidos para Servidor: $IncludedCount" -ForegroundColor Green
    Write-Host "   Mods Omitidos (Client-Only/Incompatibles): $ExcludedCount" -ForegroundColor DarkGray
    Write-Host "==================================================" -ForegroundColor Yellow
    return
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
    [System.IO.File]::WriteAllText($VoiceConfigFile, $vContent)
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
    [System.IO.File]::WriteAllText($RunShPath, $RunShContent)
}

Write-Host "[5/8] Configurando server.properties y eula.txt..." -ForegroundColor Yellow
[System.IO.File]::WriteAllText((Join-Path $StagingDir "eula.txt"), "eula=true")

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
[System.IO.File]::WriteAllText((Join-Path $StagingDir "server.properties"), $ServerProps)

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
[System.IO.File]::WriteAllText((Join-Path $StagingDir "manifest.json"), $ManifestJson)
[System.IO.File]::WriteAllText((Join-Path $FinalOutputDir "manifest.json"), $ManifestJson)

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
[System.IO.File]::WriteAllText((Join-Path $FinalOutputDir "checksums.sha256"), $ChecksumContent)

# Limpiar staging
Remove-Item -Recurse -Force $StagingDir

$ArchiveSizeMB = [math]::Round(((Get-Item $TarGzPath).Length / 1MB), 2)
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   BUNDLE CREADO EXITOSAMENTE" -ForegroundColor Green
Write-Host "   Archivo: $TarGzPath" -ForegroundColor Green
Write-Host "   Tamano: $ArchiveSizeMB MB" -ForegroundColor Green
Write-Host "   SHA-256: $Hash" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
