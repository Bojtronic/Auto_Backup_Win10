# ============================================================
# CONFIGURACIÓN GENERAL (AJUSTABLE)
# ============================================================

# Carpeta base en el EQUIPO REMOTO (UNC)
$origenBase = "\\Atm-naranjo\E\Store02"

# Carpeta destino local del backup
$destinoBase = "D:\Backup"

# Cantidad de días hacia atrás que se deben conservar (incluye HOY)
$diasAtras = 120


# ============================================================
# CONFIGURACIÓN DE LOGS
# ============================================================

$logBase = "D:\Logs"
$logOk = Join-Path $logBase "backup_OK.log"
$logErrDir = Join-Path $logBase "Errores"

if (!(Test-Path $logBase)) { New-Item -ItemType Directory -Path $logBase | Out-Null }
if (!(Test-Path $logErrDir)) { New-Item -ItemType Directory -Path $logErrDir | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logError = Join-Path $logErrDir "backup_ERROR_$timestamp.log"

function Log-OK ($msg) {
    Add-Content $logOk "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
}

function Log-ERR ($msg) {
    Add-Content $logError "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
}


# ============================================================
# GENERAR MAPA MMDD → AÑO CORRECTO
# ============================================================

$hoy = (Get-Date).Date

# Ejemplo:
# 0101 -> 2026
# 1231 -> 2025
$fechasValidas = @{}

for ($i = 0; $i -le $diasAtras; $i++) {
    $fecha = $hoy.AddDays(-$i)
    $mmdd = $fecha.ToString("MMdd")
    $anio = $fecha.Year
    $fechasValidas[$mmdd] = $anio
}


# ============================================================
# ROBOCOPY
# ============================================================

$robocopy = "C:\Windows\System32\Robocopy.exe"
$copiaExitosa = $true

"" | Set-Content $logOk
Log-OK "===== INICIO DE BACKUP ====="
Log-OK "Días a conservar: $diasAtras"


# ============================================================
# COPIA DE ARCHIVOS FILTRADOS POR AÑO
# ============================================================

Get-ChildItem $origenBase -Directory | ForEach-Object {

    $camara = $_
    $destinoCamara = Join-Path $destinoBase $camara.Name

    if (!(Test-Path $destinoCamara)) {
        New-Item -ItemType Directory -Path $destinoCamara | Out-Null
    }

    # Recorremos carpetas MMDD
    Get-ChildItem $camara.FullName -Directory | ForEach-Object {

        $mmdd = $_.Name

        if ($fechasValidas.ContainsKey($mmdd)) {

            $anioValido = $fechasValidas[$mmdd]
            $destinoMMDD = Join-Path $destinoCamara $mmdd

            if (!(Test-Path $destinoMMDD)) {
                New-Item -ItemType Directory -Path $destinoMMDD | Out-Null
            }

            # ----------------------------------------------------
            # LIMPIEZA PREVIA DEL CONTENIDO DEL DESTINO MMDD
            # Esto garantiza que NO queden archivos de otros años
            # ----------------------------------------------------
            Get-ChildItem $destinoMMDD -File -ErrorAction SilentlyContinue | Remove-Item -Force

            # Recorremos archivos dentro del MMDD
            Get-ChildItem $_.FullName -File | ForEach-Object {

                # Extraer año del nombre: EventYYYY...
                if ($_.Name -match '^Event(\d{4})') {

                    $anioArchivo = [int]$Matches[1]

                    if ($anioArchivo -eq $anioValido) {

                        Log-OK "Copiando archivo válido: $($_.FullName)"

                        Copy-Item `
                            $_.FullName `
                        (Join-Path $destinoMMDD $_.Name) `
                            -Force `
                            -ErrorAction Stop
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

    Log-ERR "Se detectaron errores. NO se realizó limpieza"
}
