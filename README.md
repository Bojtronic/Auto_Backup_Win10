# 📦 Sistema de Backups con Robocopy y PowerShell

Este repositorio contiene scripts y documentación para implementar un
**sistema de copias de seguridad automatizado** utilizando **Robocopy**
y **PowerShell** en sistemas Windows.

> 📌 **Entorno de pruebas:** Todos los procedimientos, comandos y
> scripts descritos fueron **probados en Windows 10**.



**REVISAR EL ARCHIVO LLAMADO "Manual de usuario.pdf" EL CUAL SE INCLUYE EN ESTE REPOSITORIO**

------------------------------------------------------------------------

## 📑 Contenido

-   [🚀 ¿Qué es Robocopy?](#-qué-es-robocopy)
-   [📄 Archivos `.bat`](#-archivos-bat)
    -   [📁 BACKUP_COMPLETO.bat](#-backup_completobat)
-   [⚙️ Parámetros importantes de
    Robocopy](#-parámetros-importantes-de-robocopy)
-   [❗ Buenas prácticas al copiar discos
    completos](#-buenas-prácticas-al-copiar-discos-completos)
-   [🧠 Scripts PowerShell (.ps1)](#-scripts-powershell-ps1)
-   [🧭 Guía para ejecutar scripts
    `.ps1`](#-guía-para-ejecutar-scripts-ps1)
-   [⏰ Programar el backup con el Programador de
    tareas](#-programar-el-backup-con-el-programador-de-tareas)
-   [✅ Resultado final](#-resultado-final)

------------------------------------------------------------------------

## 🚀 ¿Qué es Robocopy?

**Robocopy (Robust File Copy)** es una herramienta nativa de Windows
diseñada para copiar archivos y carpetas de forma:

-   ✅ Robusta\
-   ✅ Confiable\
-   ✅ Automatizable

Ideal para procesos de **respaldo y sincronización**.

### 📍 Ubicación del ejecutable

``` text
C:\Windows\System32\Robocopy.exe
```

### 🧩 Estructura básica de un comando Robocopy (ejemplo)

```cmd
Robocopy.exe "C:\Users\Monitoreo\Documents\BACKUP TEST ORIGEN" "C:\Users\Monitoreo\Desktop\BACKUP TEST DESTINO" /E /MIR /R:1 /W:1 /MT:16
```

Este comando se compone de las siguientes partes:

1.  Robocopy.exe:

Ejecutable de la herramienta Robocopy.

2.  Ruta del origen:

Carpeta desde donde se copiarán los archivos. 👉 "C:\Users\Monitoreo\Documents\BACKUP TEST ORIGEN"

3.  Ruta del destino:

Carpeta donde se copiarán los archivos. 👉 "C:\Users\Monitoreo\Desktop\BACKUP TEST DESTINO"

4.  Parámetros:

Opciones que controlan el comportamiento de la copia:

    -   /E → Copia subcarpetas, incluso las vacías.

    -   /MIR → Refleja el origen en el destino (sincronización espejo).

    -   /R:1 → Reintenta la copia 1 vez si hay error.

    -   /W:1 → Espera 1 segundo entre reintentos.

    -   /MT:16 → Crea copias multiproceso con 16 subprocesos (hilos).
    ⚠️ ¡Cuidado! Sin el hardware apropiado más hilos solo generan overhead.


### 📚 Documentación oficial de robocopy 

-   Microsoft Docs:\
    https://learn.microsoft.com/es-es/windows-server/administration/windows-commands/robocopy

------------------------------------------------------------------------

## 📄 Archivos `.bat`

Un archivo **`.bat`** es un script por lotes que ejecuta comandos de
Windows de forma secuencial.

### 🔧 Cómo crear un archivo `.bat`

1.  Crear un archivo de texto plano
2.  Cambiar la extensión de `.txt` a `.bat`
3.  Si las extensiones están ocultas:
    -   Explorador de archivos → **Vista**
    -   **Opciones**
    -   **Cambiar opciones de carpeta y búsqueda**
    -   Pestaña **Ver**
    -   Desmarcar **Ocultar extensiones de archivo conocidas**

✏️ El archivo puede editarse con **Bloc de notas**.

------------------------------------------------------------------------

## 📁 BACKUP_COMPLETO.bat

Este archivo realiza una **copia completa del contenido visible de una
unidad**, excluyendo:

-   Metadatos del volumen NTFS
-   Carpetas del sistema
-   Papelera de reciclaje

### 📜 Contenido del archivo

``` bat
C:\Windows\System32\Robocopy "\\Atm-naranjo\E" "D:\Backup" /E /COPY:DAT /DCOPY:T /MT:16 /R:1 /W:1 /XJ /XD "System Volume Information" "$RECYCLE.BIN"
```

### ▶️ Ejecución

Para ejecutar el backup basta con **hacer doble clic** sobre el archivo:

``` text
BACKUP_COMPLETO.bat
```

------------------------------------------------------------------------

## ⚙️ Parámetros importantes de Robocopy

### 🔹 `/E`

Copia todos los subdirectorios, incluidos los vacíos.\
Sin `/E` solo se copiarían carpetas con contenido.

### 🔹 `/MIR`

Crea un espejo del directorio origen en el destino.\
Equivale a: `/E /PURGE`

> ⚠️ **Advertencia:**\
> Si se elimina algo en el origen, también se eliminará en el destino.

### 🔹 `/R:1`

Número de reintentos cuando ocurre un error al copiar un archivo.\
Valor por defecto: **1,000,000**.

### 🔹 `/W:1`

Tiempo de espera entre reintentos (en segundos).\
Valor por defecto: **30 segundos**.

### 🔹 `/MT:n`

Crea copias multiproceso con n subprocesos (hilos). n debe ser un número entero entre 1 y 128.
Por defaul n = 8, si no se usa este parámetro se usa 1 hilo
⚠️ ¡Cuidado! Sin el hardware apropiado más hilos solo generan overhead. Con base en esto se hacen las siguientes sugerencias para casos extremos:
    HDD con CPU de 2 nucleos, usar /MT:2
    SSD con CPU de 2 nucleos, usar /MT:8

------------------------------------------------------------------------

## ❗ Buenas prácticas al copiar discos completos

❌ **Nunca copiar el root de un disco usando `/MIR`**

✔️ Siempre copiar **solo el contenido visible del disco**, excluyendo:

-   Metadatos del volumen NTFS
-   Carpetas del sistema
-   Papelera de reciclaje

### ✔️ Comando recomendado

``` bat
C:\Windows\System32\Robocopy "\\Atm-naranjo\E" "D:\Backup" /E /COPY:DAT /DCOPY:T /R:1 /W:1 /XJ /XD "System Volume Information" "$RECYCLE.BIN"
```

### 📌 Explicación de opciones adicionales

| Opción       | Función                                         |
|-------------|-------------------------------------------------|
| `/COPY:DAT` | Copia datos, atributos y marcas de tiempo       |
| `/DCOPY:T`  | Conserva fechas de las carpetas                 |
| `/XJ`       | No sigue enlaces NTFS (junctions)               |
| `/XD`       | Excluye carpetas del sistema                    |

## 📝 Uso de comillas en rutas

Las comillas (`" "`) son necesarias cuando las rutas contienen
espacios.\
Se recomienda **escribirlas manualmente** en el Bloc de notas para
evitar errores de codificación al copiar y pegar.

------------------------------------------------------------------------

## 🧪 Ejemplo de backup de prueba

``` bat
Robocopy.exe "C:\Users\Monitoreo\Documents\BACKUP TEST ORIGEN" "C:\Users\Monitoreo\Desktop\BACKUP TEST DESTINO" /E /MIR /R:1 /W:1
```

------------------------------------------------------------------------

## 🧠 Scripts PowerShell (.ps1)

Un archivo **`.ps1`** es un script de PowerShell que permite automatizar
tareas avanzadas, incluyendo:

-   Lógica condicional
-   Manejo de fechas
-   Validaciones
-   Registro de logs

### 📂 Scripts incluidos

#### 🔹 BACKUP_constante.ps1

-   Script de respaldo optimizado diseñado para ejecutarse de forma frecuente y continua, manteniendo actualizado el backup de los archivos recientes con el mínimo consumo posible de recursos.
-   Analiza únicamente las carpetas correspondientes al rango de días configurado, pero solo realiza validación detallada de archivos en la carpeta correspondiente al día actual.
-   Solo se copian archivos que existen en el origen pero aún no están en el destino.
-   Se eliminan automáticamente las carpetas que quedan fuera del rango de días configurado.

#### 🔹 BACKUP_CARPETAS_FECHAS_RECIENTES.ps1

-   Copia **carpetas completas** con nombre `MMDD`
-   Solo dentro del rango de días configurado (por ejemplo, últimos
    **120 días**)
-   Elimina carpetas antiguas **solo si la copia fue exitosa**

#### 🔹 BACKUP_ARCHIVOS_FECHAS_RECIENTES.ps1

-   Analiza **archivo por archivo**
-   Copia únicamente archivos del **año válido**
-   Maneja correctamente el **cruce de año** (año actual o anterior)


## 🧠 Archivos Batch (.bat)

Además de los scripts de PowerShell, se incluyen dos archivos **`.bat`** que utilizan Robocopy para realizar sincronizaciones completas entre el grabador (DVR) y el almacenamiento de respaldo (NAS).

#### 🔹 BACKUP completo desde grabador a NAS.bat

-   Utiliza Robocopy para copiar todo el contenido de la carpeta de origen hacia la carpeta de destino

#### 🔹 BACKUP completo desde NAS a grabador.bat

-   Este archivo batch realiza la operación inversa del anterior, copiando todo el contenido del NAS hacia el grabador.

------------------------------------------------------------------------

## 🧭 Guía para ejecutar scripts `.ps1`

### 1️⃣ Guardar el script

**Ubicación recomendada**

``` text
C:\Scripts
```

**Codificación:** UTF-8

------------------------------------------------------------------------

### 2️⃣ Verificar requisitos

-   ✔ Existe la carpeta origen, por ejemplo `E:\Store02`
-   ✔ Existen carpetas `cam01`, `cam02`, etc.
-   ✔ Existe o se puede crear `D:\Backup`
-   ✔ Permisos de lectura y escritura

------------------------------------------------------------------------

### 3️⃣ Ejecutar manualmente (primera vez)

Abrir **PowerShell como administrador** y ejecutar:

``` powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

Luego ir a la ubicación del archivo y ejecutarlo, por ejemplo:

``` powershell
cd C:\Scripts
.\BACKUP.ps1
```

------------------------------------------------------------------------

## ⏰ Programar el backup con el Programador de tareas

Configurar una nueva tarea con:

-   **Programa:** `powershell.exe`

-   **Argumentos:**
``` text
-ExecutionPolicy Bypass -File "C:\Scripts\BACKUP_constante.ps1"
```
-   **Iniciar en:** `C:\Scripts`

### ⚙️ Recomendaciones

-   ✔ Ejecutar con privilegios más altos
-   ✔ Frecuencia: diaria
-   ✔ Reintentos: 3 cada 5 minutos

------------------------------------------------------------------------

## ✅ Resultado final

El sistema de backup quedará ejecutándose **automáticamente todos los
días**, copiando únicamente los datos **relevantes**, de forma:

-   🔐 Segura
-   🎯 Controlada
-   ⚡ Eficiente
