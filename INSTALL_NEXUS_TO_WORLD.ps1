[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$WorldPath = "_work/test-world"
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   INSTALADOR MAESTRO NEXUS - INTEGRACION DE MUNDO   " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Verificar ruta del mundo
$ResolvedWorldPath = Resolve-Path $WorldPath -ErrorAction SilentlyContinue
if (-not $ResolvedWorldPath -or -not (Test-Path (Join-Path $WorldPath "level.dat"))) {
    Write-Error "ERROR CRITICO: La ruta '$WorldPath' no contiene un mundo valido de Minecraft (level.dat no encontrado)."
    exit 1
}

$WorldDir = $ResolvedWorldPath.Path
Write-Host "[1/6] Mundo detectado correctamente en: $WorldDir" -ForegroundColor Green

# 2. Verificar estado de sesion (Lock check)
$LockFile = Join-Path $WorldDir "session.lock"
if (Test-Path $LockFile) {
    try {
        $fileStream = [System.IO.File]::Open($LockFile, 'Open', 'ReadWrite', 'None')
        $fileStream.Close()
    } catch {
        Write-Error "ABORTANDO: El mundo parece estar abierto en Minecraft o en el servidor (session.lock bloqueado)."
        exit 1
    }
}
Write-Host "[2/6] Verificacion de bloqueo de sesion aprobada (Mundo cerrado)." -ForegroundColor Green

# 3. Crear Backup ZIP seguro
$BackupDir = Join-Path $PSScriptRoot "backups"
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$WorldName = (Get-Item $WorldDir).Name
$BackupZipPath = Join-Path $BackupDir "BACKUP_${WorldName}_${Timestamp}.zip"

Write-Host "[3/6] Creando copia de seguridad ZIP en: $BackupZipPath..." -ForegroundColor Yellow
Compress-Archive -Path "$WorldDir\*" -DestinationPath $BackupZipPath -CompressionLevel Optimal

# 4. Calcular Hash SHA-256
$Hash = (Get-FileHash -Path $BackupZipPath -Algorithm SHA256).Hash
Write-Host "[4/6] Backup verificado. SHA-256: $Hash" -ForegroundColor Green

# 5. Instalar Datapack NEXUS
$DatapackSource = Join-Path $PSScriptRoot "src/datapacks/nexus_progression"
$DatapackTargetDir = Join-Path $WorldDir "datapacks/nexus_progression"

if (Test-Path $DatapackTargetDir) {
    Remove-Item -Path $DatapackTargetDir -Recurse -Force
}

Write-Host "[5/6] Copiando datapack de progresion NEXUS..." -ForegroundColor Yellow
Copy-Item -Path $DatapackSource -Destination $DatapackTargetDir -Recurse -Force

# 6. Registrar manifiesto de instalacion para Rollback limpio
$ManifestPath = Join-Path $WorldDir "nexus_installed_manifest.json"
$ManifestData = @{
    InstalledAt = (Get-Date).ToString("o")
    BackupZip = $BackupZipPath
    BackupSHA256 = $Hash
    InstalledDatapack = "datapacks/nexus_progression"
}
$ManifestData | ConvertTo-Json | Set-Content -Path $ManifestPath -Encoding ascii

Write-Host "[6/6] INSTALACION COMPLETADA CON EXITO." -ForegroundColor Green
Write-Host "El mundo esta listo para NEXUS." -ForegroundColor Cyan
