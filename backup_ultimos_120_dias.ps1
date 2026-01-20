# ============================
# CONFIGURACIÓN GENERAL
# ============================

# Carpeta base en el equipo remoto (UNC)
$origenBase  = "\\Atm-naranjo\E\Store02"

# Carpeta destino local
$destinoBase = "D:\Backup"

# Cantidad de días hacia atrás (incluye HOY)
$diasAtras = 120


# ============================
# GENERAR LISTA DE MMDD VÁLIDOS
# ============================

# Fecha actual normalizada
$hoy = (Get-Date).Date

# Conjunto de carpetas válidas (MMDD)
$carpetasValidas = @{}

for ($i = 0; $i -le $diasAtras; $i++) {
    $fecha = $hoy.AddDays(-$i)
    $mmdd  = $fecha.ToString("MMdd")
    $carpetasValidas[$mmdd] = $true
}


# ============================
# RUTA DE ROBOCOPY
# ============================

$robocopy = "C:\Windows\System32\Robocopy.exe"


# ============================
# RECORRIDO DE CÁMARAS
# ============================

Get-ChildItem $origenBase -Directory | ForEach-Object {

    $camara = $_
    $destinoCamara = Join-Path $destinoBase $camara.Name

    if (!(Test-Path $destinoCamara)) {
        New-Item -ItemType Directory -Path $destinoCamara | Out-Null
    }

    # ============================
    # RECORRIDO DE CARPETAS MMDD
    # ============================

    Get-ChildItem $camara.FullName -Directory | ForEach-Object {

        $nombre = $_.Name

        # Validar formato MMDD
        if ($nombre -match '^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$') {

            # Si la carpeta está dentro del rango válido
            if ($carpetasValidas.ContainsKey($nombre)) {

                $origenFinal  = $_.FullName
                $destinoFinal = Join-Path $destinoCamara $nombre

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
            }
        }
    }
}
