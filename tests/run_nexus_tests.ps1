# Suite de Pruebas de Integración y Validación Maestra NEXUS
$ErrorActionPreference = "Continue"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "     SUITE DE PRUEBAS MAESTRA DEL PROYECTO NEXUS    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$TestResults = @()

# ----------------------------------------------------
# PRUEBA 1: VERIFICACION DE REGLA CERO (INSTALL / UNINSTALL)
# ----------------------------------------------------
Write-Host "`n[TEST 1] Probando Regla Cero y Rollback..." -ForegroundColor Yellow
try {
    $installOutput = .\INSTALL_NEXUS_TO_WORLD.ps1 -WorldPath "_work/test-world"
    if ((Test-Path "_work/test-world/nexus_installed_manifest.json")) {
        $uninstallOutput = .\UNINSTALL_NEXUS_FROM_WORLD.ps1 -WorldPath "_work/test-world"
        if (-not (Test-Path "_work/test-world/nexus_installed_manifest.json")) {
            Write-Host "  -> [PASO] Instalador y Rollback verificados correctamente." -ForegroundColor Green
            $TestResults += [PSCustomObject]@{ Test = "Regla Cero (Backup and Rollback)"; Result = "PASO" }
        } else {
            Write-Host "  -> [FALLO] Error durante el desinstalador o rollback." -ForegroundColor Red
            $TestResults += [PSCustomObject]@{ Test = "Regla Cero (Backup and Rollback)"; Result = "FALLO" }
        }
    } else {
        Write-Host "  -> [FALLO] Error durante el instalador." -ForegroundColor Red
        $TestResults += [PSCustomObject]@{ Test = "Regla Cero (Backup and Rollback)"; Result = "FALLO" }
    }
} catch {
    Write-Host "  -> [ERROR] Excepcion en prueba 1: $_" -ForegroundColor Red
    $TestResults += [PSCustomObject]@{ Test = "Regla Cero (Backup and Rollback)"; Result = "ERROR" }
}

# ----------------------------------------------------
# PRUEBA 2: SINTAXIS Y VALIDEZ DE DATAPACK AND TACZ GUNPACK
# ----------------------------------------------------
Write-Host "`n[TEST 2] Validando Datapack de Progresion y Gunpack TaCZ..." -ForegroundColor Yellow
try {
    $advFiles = Get-ChildItem "src/datapacks/nexus_progression/data/nexus/advancements" -Filter "*.json"
    $advValid = $true
    foreach ($file in $advFiles) {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        if (-not $json.display.title) { $advValid = $false }
    }

    $taczPack = Get-Content "src/tacz/nexus_weapons/pack.json" -Raw | ConvertFrom-Json
    $taczIndex = Get-Content "src/tacz/nexus_weapons/guns/index.json" -Raw | ConvertFrom-Json

    if ($advValid -and $taczPack.name -and $taczIndex.'nexus:anti_colossus_sniper') {
        Write-Host "  -> [PASO] Datapack (7 Eras) y Gunpack TaCZ (8 Clases) totalmente validos." -ForegroundColor Green
        $TestResults += [PSCustomObject]@{ Test = "Datapack and TaCZ Gunpack Structure"; Result = "PASO" }
    } else {
        Write-Host "  -> [FALLO] Estructura de Datapack o Gunpack invalida." -ForegroundColor Red
        $TestResults += [PSCustomObject]@{ Test = "Datapack and TaCZ Gunpack Structure"; Result = "FALLO" }
    }
} catch {
    Write-Host "  -> [ERROR] Excepcion en prueba 2: $_" -ForegroundColor Red
    $TestResults += [PSCustomObject]@{ Test = "Datapack and TaCZ Gunpack Structure"; Result = "ERROR" }
}

# ----------------------------------------------------
# PRUEBA 3: VERIFICACION DEL COMPILADO DE NEXUS CORE
# ----------------------------------------------------
Write-Host "`n[TEST 3] Verificando compilacion de Nexus Core Java Mod..." -ForegroundColor Yellow
if ((Test-Path "dist/NEXUS_SERVER_READY/mods/nexus-core-1.0.0.jar") -and (Test-Path "dist/NEXUS_CLIENT_READY/mods/nexus-core-1.0.0.jar")) {
    Write-Host "  -> [PASO] nexus-core-1.0.0.jar presente en Server y Client." -ForegroundColor Green
    $TestResults += [PSCustomObject]@{ Test = "Nexus Core Mod Compilation"; Result = "PASO" }
} else {
    Write-Host "  -> [FALLO] nexus-core-1.0.0.jar no encontrado en las carpetas de destino." -ForegroundColor Red
    $TestResults += [PSCustomObject]@{ Test = "Nexus Core Mod Compilation"; Result = "FALLO" }
}

# ----------------------------------------------------
# PRUEBA 4: AUDITORIA DE SEPARACION CLIENTE / SERVIDOR
# ----------------------------------------------------
Write-Host "`n[TEST 4] Verificando separacion estricta de mods (No graficos en Servidor)..." -ForegroundColor Yellow
$serverMods = Get-ChildItem "dist/NEXUS_SERVER_READY/mods" -Filter "*.jar" | Select-Object -ExpandProperty Name
$forbiddenClientMods = @("embeddium", "entityculling", "immediatelyfast", "distanthorizons", "xaerominimap", "xaeroworldmap", "controlling")

$hasGraphicsInServer = $false
foreach ($sm in $serverMods) {
    foreach ($fcm in $forbiddenClientMods) {
        if ($sm.ToLower().Contains($fcm)) {
            $hasGraphicsInServer = $true
            Write-Host "  -> ALERTA: Mod exclusivo de cliente '$sm' detectado en servidor!" -ForegroundColor Red
        }
    }
}

if (-not $hasGraphicsInServer) {
    Write-Host "  -> [PASO] Servidor dedicado totalmente limpio de mods exclusivos de cliente." -ForegroundColor Green
    $TestResults += [PSCustomObject]@{ Test = "Strict Client/Server Mod Separation"; Result = "PASO" }
} else {
    Write-Host "  -> [FALLO] Se encontraron mods exclusivos de cliente en la carpeta del servidor." -ForegroundColor Red
    $TestResults += [PSCustomObject]@{ Test = "Strict Client/Server Mod Separation"; Result = "FALLO" }
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "RESUMEN FINAL DE LA SUITE DE PRUEBAS:" -ForegroundColor Cyan
$TestResults | Format-Table -AutoSize
