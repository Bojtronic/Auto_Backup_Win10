# ============================================================
# CONFIGURACIÓN GENERAL (AJUSTABLE)
# ============================================================

# Carpeta base en el EQUIPO REMOTO (UNC)
$origenBase  = "\\Atm-naranjo\E\Store02"

# Carpeta destino local del backup
$destinoBase = "D:\Backup"

# Cantidad de días hacia atrás que se deben conservar (incluye HOY)
$diasAtras   = 120


# ============================================================
# CONFIGURACIÓN DE LOGS
# ============================================================

# Carpeta base de logs
$logBase = "D:\Logs"

# Log de ejecución EXITOSA (siempre se sobrescribe)
$logOk   = Join-Path $logBase "backup_OK.log"

# Carpeta de logs de error (históricos)
$logErrDir = Join-Path $logBase "Errores"

# Crear carpetas de logs si no existen
if (!(Test-Path $logBase))    { New-Item -ItemType Directory -Path $logBase | Out-Null }
if (!(Test-Path $logErrDir))  { New-Item -ItemType Directory -Path $logErrDir | Out-Null }

# Log de error con fecha/hora (solo si falla)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logError  = Join-Path $logErrDir "backup_ERROR_$timestamp.log"

# Función para escribir en log OK (sobrescribible)
function Log-OK($msg) {
    Add-Content -Path $logOk -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
}

# Función para escribir en log de error
function Log-ERR($msg) {
    Add-Content -Path $logError -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
}


# ============================================================
# FECHAS Y CARPETAS VÁLIDAS (MMDD)
# ============================================================

# Fecha actual normalizada (sin hora)
$hoy = (Get-Date).Date

# HashTable con las carpetas válidas (0101, 0120, etc.)
$carpetasValidas = @{}

for ($i = 0; $i -le $diasAtras; $i++) {
    $mmdd = $hoy.AddDays(-$i).ToString("MMdd")
    $carpetasValidas[$mmdd] = $true
}


# ============================================================
# ROBOCOPY
# ============================================================

$robocopy = "C:\Windows\System32\Robocopy.exe"

# Bandera de control: SOLO si todo copia bien se permitirá borrar
$copiaExitosa = $true

# Limpiar log OK al inicio (nuevo ciclo)
"" | Set-Content $logOk
Log-OK "===== INICIO DE BACKUP ====="
Log-OK "Origen: $origenBase"
Log-OK "Destino: $destinoBase"
Log-OK "Días a conservar: $diasAtras"


# ============================================================
# COPIA DE CARPETAS VÁLIDAS
# ============================================================

Get-ChildItem $origenBase -Directory | ForEach-Object {

    $camara = $_
    $destinoCamara = Join-Path $destinoBase $camara.Name

    if (!(Test-Path $destinoCamara)) {
        New-Item -ItemType Directory -Path $destinoCamara | Out-Null
        Log-OK "Creada carpeta destino: $destinoCamara"
    }

    Get-ChildItem $camara.FullName -Directory | ForEach-Object {

        $nombre = $_.Name

        # Validar formato MMDD
        if ($nombre -match '^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$') {

            if ($carpetasValidas.ContainsKey($nombre)) {

                $origenFinal  = $_.FullName
                $destinoFinal = Join-Path $destinoCamara $nombre

                Log-OK "Copiando $origenFinal → $destinoFinal"

                & $robocopy `
                    "$origenFinal" `
                    "$destinoFinal" `
                    /E `
                    /COPY:DAT `
                    /DCOPY:T `
                    /R:1 `
                    /W:1 `
                    /XJ `
                    /XD "System Volume Information" "$RECYCLE.BIN"

                # Evaluar resultado de Robocopy
                if ($LASTEXITCODE -ge 8) {
                    $copiaExitosa = $false
                    Log-ERR "ERROR copiando $origenFinal (Código Robocopy: $LASTEXITCODE)"
                }
            }
        }
    }
}


# ============================================================
# LIMPIEZA DEL DESTINO (SOLO SI TODO SALIÓ BIEN)
# ============================================================

if ($copiaExitosa) {

    Log-OK "Inicio de limpieza de carpetas antiguas"

    Get-ChildItem $destinoBase -Directory | ForEach-Object {

        $destinoCamara = $_

        Get-ChildItem $destinoCamara.FullName -Directory | ForEach-Object {

            $nombre = $_.Name

            if ($nombre -match '^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$') {

                if (-not $carpetasValidas.ContainsKey($nombre)) {

                    Log-OK "Eliminando carpeta antigua: $($_.FullName)"
                    Remove-Item $_.FullName -Recurse -Force
                }
            }
        }
    }

    Log-OK "Backup finalizado CORRECTAMENTE"

} else {

    Log-ERR "Se detectaron errores. NO se realizó limpieza del destino."
}
