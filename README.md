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
-   [🧠 Arquitectura general](#-arquitectura-general)
-   [📂 Scripts de PowerShell `.ps1`](#-scripts-de-powershell)
    -   [⚡ BACKUP_constante.ps1](#1--backup_constanteps1)
    -   [🚀 BACKUP_CARPETAS_FECHAS_RECIENTES.ps1](#2--backup_carpetas_fechas_recientesps1)
    -   [🔎 BACKUP_ARCHIVOS_FECHAS_RECIENTES.ps1](#3--backup_archivos_fechas_recientesps1)
-   [📄 Archivos batch `.bat`](#-archivos-bat)
    -   [📦 BACKUP completo desde grabador a NAS.bat](#4--backup-completo-desde-grabador-a-nasbat)
    -   [🔄 BACKUP completo desde NAS a grabador.bat](#5--backup-completo-desde-nas-a-grabadorbat)
-   [⏱️ Estrategia recomendada](#️-estrategia-recomendada)
-   [⚠️ Consideraciones](#️-consideraciones)
-   [⚙️ Parámetros importantes de Robocopy](#️-parámetros-importantes-de-robocopy)
-   [❗ Buenas prácticas al copiar discos completos](#-buenas-prácticas-al-copiar-discos-completos)
-   [📝 Uso de comillas en rutas](#-uso-de-comillas-en-rutas)
-   [🧪 Ejemplo de backup](#-ejemplo-de-backup)
-   [🧭 Guía para ejecutar scripts `.ps1`](#-guía-para-ejecutar-scripts-ps1)
-   [⏰ Programar el backup con el Programador de tareas](#-programar-el-backup-con-el-programador-de-tareas)
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

## 🧠 Arquitectura general

El sistema se basa en cuatro niveles:

- ⚡ Backup continuo (muy rápido y ligero)
- 🚀 Backup por carpetas (rápido)
- 🔎 Backup por archivos (lento)
- 📦 Backup completo (sincronización total)

---

## 📂 Scripts de PowerShell

Un archivo `.ps1` es un script de PowerShell que permite automatizar tareas en Windows mediante comandos más avanzados que los archivos `.bat`, incluyendo manejo de archivos, lógica condicional y ejecución de procesos.

### 1. ⚡ BACKUP_constante.ps1
Backup incremental optimizado para ejecución frecuente.

- Analiza carpetas de los últimos N días (ej: 120)
- Verifica archivo por archivo solo el día actual
- Copia únicamente archivos faltantes
- No elimina archivos existentes
- Elimina carpetas fuera del rango

✔ Muy bajo consumo  
✔ Ideal para ejecución continua  

---

### 2. 🚀 BACKUP_CARPETAS_FECHAS_RECIENTES.ps1
Backup rápido sin validación interna de cada carpeta.

- Copia carpetas completas recientes (formato MMDD)
- Usa Robocopy recursivo
- Elimina carpetas fuera del rango

✔ Rápido  
❗ No valida contenido interno  

---

### 3. 🔎 BACKUP_ARCHIVOS_FECHAS_RECIENTES.ps1
Backup con verificación completa de integridad.

- Analiza archivos dentro del rango de días
- Valida formato: `EventYYYY`
- Verifica coherencia de año
- Elimina contenido destino antes de copiar
- Copia solo archivos válidos

✔ Alta integridad de datos  
❗ Mayor tiempo de ejecución  

---

## 📄 Archivos `.bat`

Un archivo `.bat` ejecuta comandos de Windows de forma secuencial.

---

### 4. 📦 BACKUP completo desde grabador a NAS.bat

Copia completa desde el grabador hacia el almacenamiento de respaldo.

```bat
Robocopy "\Atm-naranjo\E\Store01" "D:\Backup" /E /COPY:DAT /DCOPY:T /MT:16 /R:1 /W:1 /XJ /XD "System Volume Information" "$RECYCLE.BIN"
```

✔ Backup total inicial  
✔ Sincronización completa  

---

### 5. 🔄 BACKUP completo desde NAS a grabador.bat

Restaura la información desde el backup hacia el grabador.

✔ Recuperación ante fallos  
✔ Reconstrucción del sistema  

---

## ⏱️ Estrategia recomendada

- `BACKUP_constante.ps1` → cada 5–15 minutos  
- `BACKUP_CARPETAS_FECHAS_RECIENTES.ps1` → cada hora  
- `BACKUP_ARCHIVOS_FECHAS_RECIENTES.ps1` → 1 vez al día  
- Backups completos (`.bat`) → semanal o mensual  

---

## ⚠️ Consideraciones

- La validación completa solo ocurre en el script por archivos
- Dependencia del formato de nombres (`EventYYYY`) (sistema GeoVision)


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

## 🧪 Ejemplo de backup

``` bat
Robocopy.exe "C:\Users\Monitoreo\Documents\BACKUP TEST ORIGEN" "C:\Users\Monitoreo\Desktop\BACKUP TEST DESTINO" /E /MIR /R:1 /W:1
```

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
