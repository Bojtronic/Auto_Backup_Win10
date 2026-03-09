# ============================================================
# CONFIGURACIÓN GENERAL
# Define rutas principales y rango de días a conservar
# ============================================================

$origenBase  = "\\Atm-naranjo\E\Store02"
$destinoBase = "D:\Backup"
$diasAtras   = 120


# ============================================================
# CONFIGURACIÓN DE LOGS
# Se definen rutas para logs de operación y errores
# ============================================================

$logBase   = "D:\Logs"
$logOk     = Join-Path $logBase "backup_OK.log"
$logErrDir = Join-Path $logBase "Errores"

# Crear carpetas si no existen
if (!(Test-Path $logBase))   { New-Item -ItemType Directory -Path $logBase   | Out-Null }
if (!(Test-Path $logErrDir)) { New-Item -ItemType Directory -Path $logErrDir | Out-Null }

# Crear log de error único por ejecución
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logError  = Join-Path $logErrDir "backup_ERROR_$timestamp.log"

# Funciones simples para escribir en logs
function Log-OK ($msg)  { Add-Content $logOk   "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg" }
function Log-ERR ($msg) { Add-Content $logError "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg" }


# ============================================================
# GENERAR MAPA DE FECHAS VÁLIDAS
# Se crea un mapa:
# MMDD => AÑO CORRECTO
#
# Esto permite saber qué año corresponde a cada carpeta
# considerando cambios de año (ej: diciembre -> enero)
# ============================================================

$hoy = (Get-Date).Date
$manana = $hoy.AddDays(1)

$mmddHoy = $hoy.ToString("MMdd")

$fechasValidas = @{}

for ($i = 0; $i -le $diasAtras; $i++) {

    $fecha = $manana.AddDays(-$i)

    $mmdd = $fecha.ToString("MMdd")
    $fechasValidas[$mmdd] = $fecha.Year
}


# ============================================================
# CONFIGURACIÓN ROBOCOPY
# Robocopy se usa para copiar archivos individuales
# ============================================================

$robocopy = "C:\Windows\System32\Robocopy.exe"

$copiaExitosa = $true

"" | Set-Content $logOk

Log-OK "===== INICIO DE BACKUP ====="
Log-OK "Dias a conservar: $diasAtras"


# ============================================================
# RECORRER TODAS LAS CÁMARAS
# Cada subcarpeta del origen representa una cámara
# ============================================================

Get-ChildItem $origenBase -Directory | ForEach-Object {

    $camara = $_

    Log-OK "Procesando cámara: $($camara.Name)"

    $destinoCamara = Join-Path $destinoBase $camara.Name

    # Crear carpeta de cámara en destino si no existe
    if (!(Test-Path $destinoCamara)) {
        New-Item -ItemType Directory -Path $destinoCamara | Out-Null
    }


    # ============================================================
    # RECORRER CARPETAS DE FECHA (MMDD)
    # ============================================================

    Get-ChildItem $camara.FullName -Directory | ForEach-Object {

        $carpetaFecha = $_
        $mmdd = $carpetaFecha.Name


        # ========================================================
        # SOLO PROCESAR FECHAS DENTRO DEL RANGO DE DIAS
        # ========================================================

        if ($fechasValidas.ContainsKey($mmdd)) {

            $anioValido = $fechasValidas[$mmdd]

            $destinoMMDD = Join-Path $destinoCamara $mmdd


            # ====================================================
            # SI LA CARPETA NO EXISTE EN DESTINO
            # SE CONSIDERA PRIMER BACKUP DE ESA FECHA
            # ====================================================

            if (!(Test-Path $destinoMMDD)) {

                Log-OK "Creando carpeta destino: $destinoMMDD"

                New-Item -ItemType Directory -Path $destinoMMDD | Out-Null
            }


            # ====================================================
            # SOLO ANALIZAR ARCHIVOS SI:
            # 1) Es la carpeta del día actual
            # 2) La carpeta en destino está vacía (primera copia)
            # ====================================================

            $destinoVacio = -not (Get-ChildItem $destinoMMDD -File -ErrorAction SilentlyContinue)

            if ($mmdd -eq $mmddHoy -or $destinoVacio) {

                Log-OK "Revisando archivos en carpeta: $mmdd"


                # =================================================
                # RECORRER ARCHIVOS DE LA CARPETA
                # =================================================

                Get-ChildItem $carpetaFecha.FullName -File | ForEach-Object {

                    $archivo = $_

                    # =============================================
                    # VALIDAR FORMATO DEL ARCHIVO
                    # Debe comenzar con EventYYYY
                    # =============================================

                    if ($archivo.Name -match '^Event(\d{4})') {

                        $anioArchivo = [int]$Matches[1]

                        # =========================================
                        # VALIDAR QUE EL AÑO SEA EL CORRECTO
                        # =========================================

                        if ($anioArchivo -eq $anioValido) {

                            $destinoArchivo = Join-Path $destinoMMDD $archivo.Name


                            # =====================================
                            # SOLO COPIAR SI EL ARCHIVO NO EXISTE
                            # =====================================

                            if (!(Test-Path $destinoArchivo)) {

                                Log-OK "Copiando archivo nuevo: $($archivo.FullName)"

                                & $robocopy `
                                    "$($archivo.DirectoryName)" `
                                    "$destinoMMDD" `
                                    "$($archivo.Name)" `
                                    /COPY:DAT `
                                    /R:1 `
                                    /W:1 `
                                    /NFL `
                                    /NDL `
                                    /NJH `
                                    /NJS


                                # =================================
                                # DETECTAR ERRORES DE ROBOCOPY
                                # =================================

                                if ($LASTEXITCODE -ge 8) {

                                    $copiaExitosa = $false

                                    Log-ERR "ERROR copiando $($archivo.FullName) (Robocopy: $LASTEXITCODE)"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


# ============================================================
# LIMPIEZA DE CARPETAS ANTIGUAS
#
# SOLO SE EJECUTA SI NO HUBO ERRORES EN LA COPIA
#
# Se eliminan carpetas fuera del rango de días configurado
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
