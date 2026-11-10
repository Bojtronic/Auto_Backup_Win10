
# ============================================================
# CONFIGURACIÓN GENERAL (AJUSTABLE)
# ============================================================

# Dirección de red donde se encuentran las grabaciones originales.
# \\Atm-naranjo = nombre del servidor.
# E\Store02 = unidad E: y carpeta Store02 compartida.
$origenBase = "\\Atm-naranjo\E\Store02"

# Carpeta local donde se guardarán las copias de seguridad.
$destinoBase = "D:\Backup"

# Cantidad de días hacia atrás que queremos conservar.
# En este caso, se trabajará con los últimos 120 días.
$diasAtras = 120


# ============================================================
# CONFIGURACIÓN DE LOGS (REGISTRO DE ACTIVIDAD)
# ============================================================

# Carpeta principal donde se guardarán los registros.
$logBase = "D:\Logs"

# Archivo donde se registrarán las operaciones correctas.
$logOk = Join-Path $logBase "backup_OK.log"

# Carpeta donde se guardarán los archivos de errores.
$logErrDir = Join-Path $logBase "Errores"

# Comprueba si existe la carpeta D:\Logs.
# Si no existe, la crea.
if (!(Test-Path $logBase)) {
    New-Item -ItemType Directory -Path $logBase | Out-Null
}

# Comprueba si existe la carpeta de errores.
# Si no existe, también la crea.
if (!(Test-Path $logErrDir)) {
    New-Item -ItemType Directory -Path $logErrDir | Out-Null
}

# Obtiene la fecha y hora actuales.
# Ejemplo: 20261109_230500.
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Construye el nombre del archivo de errores.
# Cada ejecución tendrá su propio archivo de errores.
$logError = Join-Path $logErrDir "backup_ERROR_$timestamp.log"


# ============================================================
# FUNCIONES PARA ESCRIBIR EN LOS LOGS
# ============================================================

# Define una función llamada Log-OK.
# Recibe un mensaje y lo agrega al archivo de operaciones correctas.
function Log-OK ($msg) {

    # Get-Date obtiene la fecha y hora.
    # Add-Content agrega el mensaje al final del archivo.
    Add-Content $logOk "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
}

# Define una función llamada Log-ERR.
# Se utiliza para registrar errores.
function Log-ERR ($msg) {

    # Agrega el mensaje al archivo de errores de esta ejecución.
    Add-Content $logError "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $msg"
}


# ============================================================
# GENERAR MAPA MMDD -> AÑO CORRECTO
# ============================================================

# Obtiene la fecha actual sin incluir la hora.
$hoy = (Get-Date).Date

# Obtiene la fecha de mañana.
# Se utiliza para construir el rango de fechas.
$manana = $hoy.AddDays(1)

# Crea una tabla de búsqueda vacía.
# Guardará las fechas con formato MMDD y el año correspondiente.
$fechasValidas = @{}

# Repite el proceso desde 0 hasta 120.
# Esto representa 121 fechas contando el día de mañana
# y el día actual, según la lógica original del script.
for ($i = 0; $i -le $diasAtras; $i++) {

    # Calcula una fecha restando días a mañana.
    $fecha = $manana.AddDays(-$i)

    # Convierte la fecha a formato MMDD.
    # Ejemplo: 15 de julio = 0715.
    # Guarda el año correspondiente como valor.
    $fechasValidas[$fecha.ToString("MMdd")] = $fecha.Year
}


# ============================================================
# CONFIGURACIÓN DE ROBOCOPY
# ============================================================

# Define la ubicación del ejecutable Robocopy de Windows.
$robocopy = "C:\Windows\System32\Robocopy.exe"

# Variable de control.
# Comienza suponiendo que todas las copias serán exitosas.
# Si ocurre un error, cambiará a $false.
$copiaExitosa = $true

# Vacía el archivo de registro de operaciones correctas.
# IMPORTANTE: elimina el contenido anterior de backup_OK.log.
"" | Set-Content $logOk

# Registra el comienzo de la ejecución.
Log-OK "===== INICIO DE BACKUP ====="

# Registra la cantidad de días configurados.
Log-OK "Dias a conservar: $diasAtras"


# ============================================================
# COPIA DE ARCHIVOS FILTRADOS POR AÑO
# ============================================================

# Busca todas las carpetas que están directamente dentro del origen.
# Cada una representa una cámara.
Get-ChildItem $origenBase -Directory | ForEach-Object {

    # Guarda la información de la cámara actual.
    $camara = $_

    # Construye la ruta de destino para esa cámara.
    # Ejemplo: D:\Backup\Camara01.
    $destinoCamara = Join-Path $destinoBase $camara.Name

    # Comprueba si ya existe la carpeta de destino.
    if (!(Test-Path $destinoCamara)) {

        # Si no existe, la crea.
        New-Item -ItemType Directory -Path $destinoCamara | Out-Null
    }

    # Busca las carpetas que están dentro de la cámara.
    # Estas carpetas representan fechas en formato MMDD.
    Get-ChildItem $camara.FullName -Directory | ForEach-Object {

        # Obtiene el nombre de la carpeta actual.
        # Ejemplo: 0715.
        $mmdd = $_.Name

        # Comprueba si esa fecha está dentro del rango permitido.
        if ($fechasValidas.ContainsKey($mmdd)) {

            # Obtiene el año que corresponde a esa fecha.
            # Ejemplo: 0715 podría corresponder a 2026.
            $anioValido = $fechasValidas[$mmdd]

            # Construye la ruta de destino de la fecha.
            # Ejemplo: D:\Backup\Camara01\0715.
            $destinoMMDD = Join-Path $destinoCamara $mmdd

            # Comprueba si existe la carpeta de destino.
            if (!(Test-Path $destinoMMDD)) {

                # Si no existe, la crea.
                New-Item -ItemType Directory -Path $destinoMMDD | Out-Null
            }

            # ------------------------------------------------
            # LIMPIEZA PREVIA DE ARCHIVOS
            # ------------------------------------------------

            # Busca los archivos que están directamente dentro
            # de la carpeta de destino de esta fecha.
            Get-ChildItem $destinoMMDD -File -ErrorAction SilentlyContinue |

                # Elimina esos archivos antes de comenzar la copia.
                # -Force permite eliminar también archivos ocultos
                # o de solo lectura cuando sea posible.
                Remove-Item -Force

            # ------------------------------------------------
            # REVISIÓN Y COPIA DE ARCHIVOS
            # ------------------------------------------------

            # Busca los archivos que están directamente dentro
            # de la carpeta de fecha del origen.
            Get-ChildItem $_.FullName -File | ForEach-Object {

                # Comprueba si el nombre comienza con Event
                # seguido de cuatro números.
                # Ejemplo: Event2026_001.
                # Los cuatro números representan el año.
                if ($_.Name -match '^Event(\d{4})') {

                    # Convierte el año encontrado a número entero.
                    $anioArchivo = [int]$Matches[1]

                    # Compara el año del archivo con el año
                    # que corresponde a la carpeta MMDD.
                    if ($anioArchivo -eq $anioValido) {

                        # Registra qué archivo se va a copiar.
                        Log-OK "Copiando archivo valido: $($_.FullName)"

                        # Guarda la carpeta donde está el archivo original.
                        $origenArchivo = $_.DirectoryName

                        # Guarda la carpeta donde se copiará.
                        $destinoArchivo = $destinoMMDD

                        # Guarda únicamente el nombre del archivo.
                        $nombreArchivo = $_.Name

                        # Ejecuta Robocopy.
                        # Copia el archivo indicado desde su carpeta
                        # original hacia la carpeta de respaldo.
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

                        # Robocopy devuelve un código de salida.
                        # Los códigos iguales o superiores a 8
                        # indican que ocurrió algún error de copia.
                        if ($LASTEXITCODE -ge 8) {

                            # Marca la ejecución como no exitosa.
                            $copiaExitosa = $false

                            # Registra el archivo que produjo el error
                            # y el código devuelto por Robocopy.
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

# Comprueba si la variable continúa siendo verdadera.
# Es decir, si no se detectaron errores de Robocopy.
if ($copiaExitosa) {

    # Registra que comienza el proceso de limpieza.
    Log-OK "Inicio limpieza de carpetas antiguas"

    # Recorre todas las carpetas de cámaras del destino.
    Get-ChildItem $destinoBase -Directory | ForEach-Object {

        # Dentro de cada cámara busca las carpetas MMDD.
        Get-ChildItem $_.FullName -Directory | ForEach-Object {

            # Comprueba si el nombre de la carpeta MMDD
            # NO está dentro de las fechas válidas.
            if (-not $fechasValidas.ContainsKey($_.Name)) {

                # Registra qué carpeta se va a eliminar.
                Log-OK "Eliminando carpeta antigua: $($_.FullName)"

                # Elimina la carpeta completa y todo su contenido.
                # -Recurse elimina subcarpetas y archivos.
                # -Force fuerza la eliminación cuando es posible.
                Remove-Item $_.FullName -Recurse -Force
            }
        }
    }

    # Registra que el proceso terminó correctamente.
    Log-OK "Backup finalizado CORRECTAMENTE"
}
else {

    # Si hubo errores, no ejecuta la limpieza.
    # Esto evita borrar carpetas antiguas cuando una copia falló.
    Log-ERR "Se detectaron errores. NO se realizo limpieza"
}
