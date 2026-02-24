# Análisis: Sistema de Build e Instalador

**Fecha:** 23 de febrero de 2026  
**Commit:** 5b12e22

## Resumen

El sistema de build y empaquetado del proyecto utiliza:
- **AutoHotkey Compiler** (Ahk2Exe.exe) - para compilar .ahk → .exe
- **PowerShell** - para crear archivos ZIP
- **Inno Setup 6** - para crear el instalador

---

## 🔧 Build Script (build.bat)

### Proceso de Build (5 pasos)

#### [1/5] Limpieza
- Elimina carpeta `dist/` si existe
- Crea nueva carpeta `dist/` vacía

#### [2/5] Compilación
```batch
Ahk2Exe.exe /in "main.ahk" /out "dist\main.exe" /icon "main.ico" /base "AutoHotkey64.exe"
```
- **Input:** main.ahk (código fuente)
- **Output:** dist\main.exe (ejecutable)
- **Icono:** main.ico (embedded)
- **Base:** AutoHotkey64.exe (runtime v2)

#### [3/5] Copia de archivos
```
dist/
├── main.exe ← compilado
├── lib/ ← bibliotecas (12 .ahk + 2 DLLs WebView2)
├── ui/ ← interfaz (menu.html)
├── *.ico ← iconos
├── config.ini ← configuración por defecto
└── README.md ← documentación
```

**20 archivos totales** (~0.87 MB sin comprimir)

#### [4/5] Distribución portable (ZIP)
```powershell
Compress-Archive -Path 'dist\*' -DestinationPath 'main-automation-dist.zip'
```
- **Output:** main-automation-dist.zip (0.87 MB)
- **Uso:** Descomprimir y ejecutar main.exe sin instalación

#### [5/5] Instalador (Inno Setup)
```batch
ISCC.exe "installer.iss"
```
- **Output:** main-automation-setup.exe (2.62 MB)
- **Compresión:** LZMA2 con SolidCompression
- **Características:** Ver sección Instalador

---

## 📦 Instalador (installer.iss)

### Información General

```ini
Nombre:      Main Automation
Versión:     1.0.0
Publisher:   JP Salazar
AppId:       {B2C3D4E5-F6A7-8901-BCDE-FG2345678901}
Dir Default: C:\Program Files\Main Automation
```

### Características

#### 1. Detección de Instalación Existente
Cuando detecta una instalación previa con settings del usuario:

```
[ ] Update (mantener settings y customizaciones) ← default
[ ] Clean install (resetear todo a defaults)
```

- **Update:** Preserva `config.ini` existente
- **Clean install:** Sobrescribe todo, elimina config anterior

#### 2. Tareas Opcionales

```
[ ] Crear icono en escritorio
[ ] Iniciar con Windows
```

**Inicio con Windows:**
- Agrega entrada en: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- Valor: `MainAutomation` → `"C:\Program Files\Main Automation\main.exe"`

#### 3. Gestión de Procesos
- **Pre-instalación:** Cierra procesos `main.exe` activos con `taskkill /f`
- **Post-instalación:** Opción para lanzar inmediatamente

#### 4. Archivos Instalados

```
{app}/
├── main.exe ← ejecutable principal
├── config.ini ← configuración (preservada en updates)
├── lib/ ← bibliotecas (12 .ahk + WebView2 DLLs)
├── ui/ ← interfaz web (menu.html)
├── *.ico ← iconos (main.ico, icon.ico)
└── README.md ← documentación
```

**Sin archivos de usuario adicionales** (skills/, commands/ fueron eliminados)

---

## ✅ Problemas Encontrados y Solucionados

### 1. Referencias a Directorios Eliminados

**Problema en installer.iss (líneas 58-61):**
```ini
Source: "dist\commands\*"; DestDir: "{app}\commands"; ...
Source: "dist\skills\*"; DestDir: "{app}\skills"; ...
Source: "dist\.skills\*"; DestDir: "{app}\.skills"; ...
```

**Problema:** Intentaba copiar directorios que ya no existen (eliminados en limpieza)

**Solución:** Eliminadas todas las referencias a `commands/`, `skills/`, `.skills/`

---

### 2. Archivo wrench.png Inexistente

**Problema en installer.iss (línea 70):**
```ini
Source: "dist\wrench.png"; DestDir: "{app}"; Flags: skipifsourcedoesntexist
```

**Problema:** El archivo fue eliminado pero seguía referenciado

**Solución:** Eliminada línea (no hay dependencia de wrench.png)

---

### 3. Error de Parsing en build.bat

**Problema:**
```
\Inno was unexpected at this time.
```

**Causa raíz:** Combinación de problemas:
1. Línea 55: `if exist "wrench.png" copy ...` sin paréntesis causaba problemas de parsing
2. Bloques `if` anidados con rutas conteniendo paréntesis `(x86)` fallan en batch

**Solución:**
```batch
# Antes (problemático):
if exist "wrench.png" copy /Y "wrench.png" "dist\" >nul
set "INNO_COMPILER=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "%INNO_COMPILER%" (
    "%INNO_COMPILER%" "installer.iss"
    ...
)

# Después (funcional):
# wrench.png eliminado
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "installer.iss"
    ...
) else (
    echo SKIPPED: Inno Setup not found...
)
```

**Técnica:** Usar `goto` y labels en lugar de bloques `if` anidados cuando hay paréntesis

---

### 4. Función HasUserSettings() Desactualizada

**Problema en installer.iss (líneas 116-122):**
```pascal
function HasUserSettings: Boolean;
begin
  Result := FileExists(InstallDir + '\config.ini') or
            DirExists(InstallDir + '\skills') or          ← no existen
            DirExists(InstallDir + '\.skills') or         ← no existen
            DirExists(InstallDir + '\commands');          ← no existen
end;
```

**Solución simplificada:**
```pascal
function HasUserSettings: Boolean;
begin
  Result := FileExists(InstallDir + '\config.ini');
end;
```

---

## 📊 Verificación del Build

### Test de Compilación Exitoso

```
[1/5] Cleaning previous build...            ✓
[2/5] Compiling main.ahk to main.exe...     ✓
[3/5] Copying required files to dist\...    ✓
[4/5] Creating zip distribution...          ✓ main-automation-dist.zip (0.87 MB)
[5/5] Creating installer with Inno Setup... ✓ main-automation-setup.exe (2.62 MB)
```

### Estructura de dist/ Generada

```
dist/ (20 archivos)
│
├── Ejecutable
│   └── main.exe (785 KB)
│
├── Configuración
│   └── config.ini (2 KB)
│
├── Recursos
│   ├── main.ico
│   ├── icon.ico
│   └── README.md
│
├── lib/ (14 archivos)
│   ├── audio.ahk
│   ├── chord-hotkeys.ahk
│   ├── clipboard.ahk
│   ├── ComVar.ahk
│   ├── globals.ahk
│   ├── logging.ahk
│   ├── Promise.ahk
│   ├── screen.ahk
│   ├── utils.ahk
│   ├── WebView2.ahk
│   ├── WebViewToo.ahk
│   ├── window.ahk
│   ├── 32bit/WebView2Loader.dll
│   └── 64bit/WebView2Loader.dll
│
└── ui/
    └── menu.html
```

---

## 🎯 Conclusiones

### Estado Final: ✅ Completamente Funcional

1. **Build script funciona correctamente** sin errores
2. **Instalador genera exitosamente** el .exe de 2.62 MB
3. **Distribución ZIP crea** archivo portable de 0.87 MB
4. **Estructura limpia** - solo archivos necesarios (20 en total)
5. **Sin dependencias fantasma** - todas las referencias obsoletas eliminadas

### Archivos de Distribución

| Archivo | Tamaño | Descripción |
|---------|--------|-------------|
| main-automation-dist.zip | 0.87 MB | Distribución portable (descomprimir y ejecutar) |
| main-automation-setup.exe | 2.62 MB | Instalador con Inno Setup (setup wizard completo) |

### Rutas de Compilador

Si necesitás cambiar de máquina, verificá estas rutas en build.bat:

```batch
set "AHK_COMPILER=C:\Users\jsa6055\AppData\Local\Programs\AutoHotkey\Compiler\Ahk2Exe.exe"
set "AHK_BASE=C:\Users\jsa6055\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe"

# Inno Setup (en línea 72):
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" ...
```

---

## 📝 Próximos Pasos (Opcionales)

### Mejoras Potenciales

1. **Versionado automático:** Leer versión desde un archivo VERSION.txt
2. **Build profiles:** Debug vs Release (con/sin logging)
3. **Code signing:** Firmar ejecutables con certificado digital
4. **Auto-update:** Sistema de actualización automática desde GitHub Releases
5. **Logs de instalación:** Guardar logs del instalador para debugging

### Testing Recomendado

- [ ] Instalar desde main-automation-setup.exe en máquina limpia
- [ ] Verificar que el ejecutable funcione correctamente
- [ ] Probar opción "Iniciar con Windows"
- [ ] Probar update sobre instalación existente (preservar config)
- [ ] Probar clean install (resetear config)
- [ ] Verificar desinstalación limpia

---

**Resultado:** Sistema de build y empaquetado completamente funcional y optimizado tras limpieza de archivos obsoletos.
