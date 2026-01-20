# 🧭 Guía completa para ejecutar el script de Backup (120 días)

Este documento explica **paso a paso** cómo ejecutar manualmente y cómo
programar el script PowerShell que copia únicamente las carpetas
correspondientes a los **últimos 120 días**.

------------------------------------------------------------------------

## 1️⃣ Guardar el script correctamente

1.  Abre **Bloc de notas**
2.  Copia todo el script PowerShell proporcionado
3.  Guarda el archivo con las siguientes opciones:

**Nombre del archivo**

    backup_ultimos_120_dias.ps1

**Ubicación recomendada**

    C:\Scripts

**Tipo**

    Todos los archivos (*.*)

**Codificación**

    UTF-8

📌 **Resultado final**

    C:\Scripts\backup_ultimos_120_dias.ps1

------------------------------------------------------------------------

## 2️⃣ Verificar permisos y rutas

Antes de ejecutar el script, confirma que:

-   ✔ Existe `E:\Store02`
-   ✔ Existen las carpetas `cam01`, `cam02`, `cam03`, etc.
-   ✔ Existe (o se puede crear) `D:\Backup`
-   ✔ El usuario que ejecuta el script tiene permisos de **lectura y
    escritura**

------------------------------------------------------------------------

## 3️⃣ Ejecutar el script manualmente (prueba inicial)

⚠️ **MUY IMPORTANTE:** la primera vez ejecútalo manualmente.

### Paso 1 -- Abrir PowerShell como administrador

1.  Presiona **Inicio**
2.  Escribe: `PowerShell`
3.  Clic derecho → **Ejecutar como administrador**

------------------------------------------------------------------------

### Paso 2 -- Permitir la ejecución del script (una sola vez)

Ejecuta el siguiente comando:

``` powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

Cuando aparezca la pregunta:

    ¿Desea cambiar la directiva de ejecución?

Responde:

    S

📌 Esto **no desprotege el sistema**, solo permite ejecutar scripts
locales.

------------------------------------------------------------------------

### Paso 3 -- Ejecutar el script

En la consola de PowerShell:

``` powershell
cd C:\Scripts
.\backup_ultimos_120_dias.ps1
```

✔ El script debe comenzar a copiar carpetas\
✔ No deben aparecer errores en rojo\
✔ Verifica que se creen carpetas en `D:\Backup\camXX`

------------------------------------------------------------------------

## 4️⃣ Validar el resultado

Revisa que existan carpetas como:

    D:\Backup\cam01\0101
    D:\Backup\cam02\1231

❌ Carpetas fuera del rango de 120 días (por ejemplo `0615`) **NO deben
copiarse**

------------------------------------------------------------------------

# ⏰ Agregar el script al Programador de tareas

## 5️⃣ Abrir el Programador de tareas

1.  Presiona **Win + R**

2.  Escribe:

        taskschd.msc

3.  Presiona **Enter**

------------------------------------------------------------------------

## 6️⃣ Crear la tarea (forma correcta)

1.  Clic en **Crear tarea**\
    ⚠️ **NO usar "Crear tarea básica"**

------------------------------------------------------------------------

### 🔹 Pestaña **General**

-   **Nombre**

        Backup Store02 - últimos 120 días

-   **Descripción**

        Copia diaria de cámaras (últimos 120 días)

-   Marca:

    -   ✅ Ejecutar con los privilegios más altos
    -   ✅ Ejecutar tanto si el usuario inició sesión como si no

------------------------------------------------------------------------

### 🔹 Pestaña **Desencadenadores**

1.  Clic en **Nuevo**
2.  Configura:
    -   Iniciar la tarea: **Según una programación**
    -   Configuración: **Diariamente**
    -   Hora: la deseada (ej. 01:00 AM)
3.  Clic en **Aceptar**

------------------------------------------------------------------------

### 🔹 Pestaña **Acciones**

1.  Clic en **Nuevo**

2.  Acción: **Iniciar un programa**

3.  **Programa o script**

        powershell.exe

4.  **Agregar argumentos**

        -ExecutionPolicy Bypass -File "C:\Scripts\backup_ultimos_120_dias.ps1"

5.  **Iniciar en**

        C:\Scripts

------------------------------------------------------------------------

### 🔹 Pestaña **Condiciones** (recomendado)

Desmarcar:

-   ❌ Iniciar la tarea solo si el equipo está con corriente alterna (si
    es servidor)
-   ❌ Detener si el equipo cambia a batería

------------------------------------------------------------------------

### 🔹 Pestaña **Configuración**

Marcar:

-   ✅ Permitir que la tarea se ejecute a petición
-   ✅ Si la tarea falla, reiniciar cada: **5 minutos**
-   **Intentos:** 3

------------------------------------------------------------------------

## 7️⃣ Probar la tarea

1.  Selecciona la tarea creada
2.  Clic derecho → **Ejecutar**
3.  Verifica que el backup se ejecute correctamente

------------------------------------------------------------------------

## ✅ Listo

El sistema de backup quedará ejecutándose **automáticamente todos los
días**, copiando únicamente los últimos **120 días reales**, sin
depender del año.
