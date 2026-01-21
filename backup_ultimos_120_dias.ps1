# ============================
# CONFIGURACIÓN GENERAL
# ============================

$origenBase  = "\\Atm-naranjo\E\Store02"
$destinoBase = "D:\Backup"
$diasAtras   = 120


# ============================
# GENERAR LISTA DE MMDD VÁLIDOS
# ============================

$hoy = (Get-Date).Date
$carpetasValidas = @{}

for ($i = 0; $i -le $diasAtras; $i++) {
    $mmdd = $hoy.AddDays(-$i).ToString("MMdd")
    $carpetasValidas[$mmdd] = $true
}


# ============================
# RUTA DE ROBOCOPY
# ============================

$robocopy = "C:\Windows\System32\Robocopy.exe"


# ============================
# COPIA DE CARPETAS VÁLIDAS
# ============================

Get-ChildItem $origenBase -Directory | ForEach-Object {

    $camara = $_
    $destinoCamara = Join-Path $destinoBase $camara.Name

    if (!(Test-Path $destinoCamara)) {
        New-Item -ItemType Directory -Path $destinoCamara | Out-Null
    }

    Get-ChildItem $camara.FullName -Directory | ForEach-Object {

        $nombre = $_.Name

        if ($nombre -match '^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$') {

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


# ============================
# LIMPIEZA DEL DESTINO (CLAVE)
# ============================

Get-ChildItem $destinoBase -Directory | ForEach-Object {

    $destinoCamara = $_

    Get-ChildItem $destinoCamara.FullName -Directory | ForEach-Object {

        $nombre = $_.Name

        if ($nombre -match '^(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$') {

            if (-not $carpetasValidas.ContainsKey($nombre)) {

                Write-Host "Eliminando carpeta antigua: $($_.FullName)"
                Remove-Item $_.FullName -Recurse -Force
            }
        }
    }
}
