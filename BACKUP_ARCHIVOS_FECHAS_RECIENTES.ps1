# ============================================================
# CONFIGURACIÓN GENERAL (AJUSTABLE)
# ============================================================

$origenBase  = "\\Atm-naranjo\E\Store02"
$destinoBase = "D:\Backup"
$diasAtras   = 120


# ============================================================
# CONFIGURACIÓN DE LOGS
# ============================================================

$logBase   = "D:\Logs"
$logOk     = Join-Path $logBase "backup_OK.log"
$logErrDir = Join-Path $logBase "Errores"

if (!(Test-Path $logBase))   { New-Item -ItemType Directory -Path $logBase   | Out-Null }
if (!(Test-Path $logErrDir)) { New-Item -ItemType Directory -Path $logErrDir | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logError  = Join-Path $logErrDir "backup_ERROR_$timestamp.log"

function Log-OK ($msg)  { Add-Content $logOk   "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg" }
function Log-ERR ($msg) { Add-Content $logError "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg" }


# ============================================================
# GENERAR MAPA MMDD → AÑO CORRECTO
# ============================================================

$hoy = (Get-Date).Date
$manana = $hoy.AddDays(1)
$fechasValidas = @{}

for ($i = 0; $i -le $diasAtras; $i++) {
    $fecha = $manana.AddDays(-$i)
    $fechasValidas[$fecha.ToString("MMdd")] = $fecha.Year
}


# ============================================================
# ROBOCOPY
# ============================================================

$robocopy = "C:\Windows\System32\Robocopy.exe"
$copiaExitosa = $true

"" | Set-Content $logOk
Log-OK "===== INICIO DE BACKUP ====="
Log-OK "Dias a conservar: $diasAtras"


# ============================================================
# COPIA DE ARCHIVOS FILTRADOS POR AÑO (CON PROGRESO EN CONSOLA)
# ============================================================

Get-ChildItem $origenBase -Directory | ForEach-Object {

    $camara = $_
    $destinoCamara = Join-Path $destinoBase $camara.Name

    if (!(Test-Path $destinoCamara)) {
        New-Item -ItemType Directory -Path $destinoCamara | Out-Null
    }

    Get-ChildItem $camara.FullName -Directory | ForEach-Object {

        $mmdd = $_.Name

        if ($fechasValidas.ContainsKey($mmdd)) {

            $anioValido   = $fechasValidas[$mmdd]
            $destinoMMDD  = Join-Path $destinoCamara $mmdd

            if (!(Test-Path $destinoMMDD)) {
                New-Item -ItemType Directory -Path $destinoMMDD | Out-Null
            }

            # Limpieza previa
            Get-ChildItem $destinoMMDD -File -ErrorAction SilentlyContinue | Remove-Item -Force

            # Archivos
            Get-ChildItem $_.FullName -File | ForEach-Object {

                if ($_.Name -match '^Event(\d{4})') {

                    $anioArchivo = [int]$Matches[1]

                    if ($anioArchivo -eq $anioValido) {

                        Log-OK "Copiando archivo valido: $($_.FullName)"

                        $origenArchivo = $_.DirectoryName
                        $destinoArchivo = $destinoMMDD
                        $nombreArchivo = $_.Name

                        & $robocopy `
                            "$origenArchivo" `
                            "$destinoArchivo" `
                            "$nombreArchivo" `
                            /COPY:DAT `
                            /MT:4 `
                            /R:1 `
                            /W:1 `
                            /NFL `
                            /NDL `
                            /NJH `
                            /NJS

                        if ($LASTEXITCODE -ge 8) {
                            $copiaExitosa = $false
                            Log-ERR "ERROR copiando $($_.FullName) (Robocopy: $LASTEXITCODE)"
                        }
                    }
                }
            }
        }
    }
}


# ============================================================
# LIMPIEZA DEL DESTINO (SOLO SI TODO SALIÓ BIEN)
# ============================================================

if ($copiaExitosa) {

    Log-OK "Inicio limpieza de carpetas antiguas"

    Get-ChildItem $destinoBase -Directory | ForEach-Object {
        Get-ChildItem $_.FullName -Directory | ForEach-Object {
            if (-not $fechasValidas.ContainsKey($_.Name)) {
                Log-OK "Eliminando carpeta antigua: $($_.FullName)"
                Remove-Item $_.FullName -Recurse -Force
            }
        }
    }

    Log-OK "Backup finalizado CORRECTAMENTE"
}
else {
    Log-ERR "Se detectaron errores. NO se realizo limpieza"
}
