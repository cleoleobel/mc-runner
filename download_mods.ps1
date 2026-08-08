# Script de descarga y verificación oficial de mods desde Modrinth API v2
$ErrorActionPreference = "Continue"

$ModsList = @(
    @{ slug = "create"; side = "BOTH" },
    @{ slug = "createaddition"; side = "BOTH" },
    @{ slug = "mekanism"; side = "BOTH" },
    @{ slug = "mekanism-generators"; side = "BOTH" },
    @{ slug = "irons-spells-n-spellbooks"; side = "BOTH" },
    @{ slug = "cataclysm-spellbooks"; side = "BOTH" },
    @{ slug = "l_enders-cataclysm"; side = "BOTH" },
    @{ slug = "eeeab-s-mobs"; side = "BOTH" },
    @{ slug = "alexs-caves"; side = "BOTH" },
    @{ slug = "timeless-and-classics-zero"; side = "BOTH" },
    @{ slug = "ironsarms"; side = "BOTH" },
    @{ slug = "curios"; side = "BOTH" },
    @{ slug = "geckolib"; side = "BOTH" },
    @{ slug = "citadel"; side = "BOTH" },
    @{ slug = "azurelib"; side = "BOTH" },
    @{ slug = "playeranimator"; side = "BOTH" },
    @{ slug = "corpse"; side = "BOTH" },
    @{ slug = "playerrevive"; side = "BOTH" },
    @{ slug = "open-parties-and-claims"; side = "BOTH" },
    @{ slug = "jei"; side = "BOTH" },
    @{ slug = "jade"; side = "BOTH" },
    @{ slug = "modernfix"; side = "BOTH" },
    @{ slug = "ferritecore"; side = "BOTH" },
    @{ slug = "spark"; side = "BOTH" },
    @{ slug = "embeddium"; side = "CLIENT" },
    @{ slug = "entityculling"; side = "CLIENT" },
    @{ slug = "immediatelyfast"; side = "CLIENT" },
    @{ slug = "distant-horizons"; side = "CLIENT" },
    @{ slug = "xaeros-minimap"; side = "CLIENT" },
    @{ slug = "xaeros-world-map"; side = "CLIENT" },
    @{ slug = "controlling"; side = "CLIENT" },
    @{ slug = "chunky"; side = "SERVER" }
)

$WorkModsDir = "_work/mods"
$ServerModsDir = "dist/NEXUS_SERVER_READY/mods"
$ClientModsDir = "dist/NEXUS_CLIENT_READY/mods"

New-Item -ItemType Directory -Force -Path $WorkModsDir, $ServerModsDir, $ClientModsDir | Out-Null

$ProgressPreference = 'SilentlyContinue'

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  DESCARGA OFICIAL DE MODS FORGE 1.20.1 (MODRINTH)  " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$DownloadResults = @()

foreach ($mod in $ModsList) {
    $slug = $mod.slug
    $side = $mod.side
    Write-Host "Consultando API de Modrinth para '$slug' (Forge 1.20.1)..." -ForegroundColor Yellow

    $apiUrl = "https://api.modrinth.com/v2/project/$slug/version?game_versions=[%221.20.1%22]&loaders=[%22forge%22]"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{ "User-Agent" = "AntigravityModDownloader/1.0" }
        if ($response -and $response.Count -gt 0) {
            $latestVersion = $response[0]
            $fileObj = $latestVersion.files | Where-Object { $_.primary -eq $true } | Select-Object -First 1
            if (-not $fileObj) { $fileObj = $latestVersion.files[0] }

            $downloadUrl = $fileObj.url
            $fileName = $fileObj.filename
            $targetPath = Join-Path $WorkModsDir $fileName

            if (-not (Test-Path $targetPath)) {
                Write-Host "  Descargando $fileName..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $downloadUrl -OutFile $targetPath
            } else {
                Write-Host "  Archivo $fileName ya existe en cache." -ForegroundColor Green
            }

            $sha256 = (Get-FileHash -Path $targetPath -Algorithm SHA256).Hash

            # Copiar segun lado de ejecucion
            if ($side -eq "BOTH" -or $side -eq "SERVER") {
                Copy-Item -Path $targetPath -Destination (Join-Path $ServerModsDir $fileName) -Force
            }
            if ($side -eq "BOTH" -or $side -eq "CLIENT") {
                Copy-Item -Path $targetPath -Destination (Join-Path $ClientModsDir $fileName) -Force
            }

            $DownloadResults += [PSCustomObject]@{
                Slug = $slug
                FileName = $fileName
                Side = $side
                SHA256 = $sha256
                Status = "OK"
            }
            Write-Host "  [OK] $fileName ($side) SHA-256: $sha256" -ForegroundColor Green
        } else {
            Write-Host "  [ALERTA] No se encontro version compatible directa para '$slug'." -ForegroundColor Red
            $DownloadResults += [PSCustomObject]@{ Slug = $slug; FileName = "N/A"; Side = $side; SHA256 = "N/A"; Status = "NOT_FOUND" }
        }
    } catch {
        Write-Host "  [ERROR] Fallo al consultar o descargar '$slug': $_" -ForegroundColor Red
        $DownloadResults += [PSCustomObject]@{ Slug = $slug; FileName = "ERROR"; Side = $side; SHA256 = "ERROR"; Status = "FAILED" }
    }
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE DESCARGAS DE MODS:" -ForegroundColor Cyan
$DownloadResults | Format-Table -AutoSize
