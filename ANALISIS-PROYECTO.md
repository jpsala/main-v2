# Análisis del Proyecto Main.ahk

## 📑 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Guía Rápida de Uso](#-guía-rápida-de-uso)
3. [Uso Principal del Sistema](#-uso-principal-del-sistema)
4. [Arquitectura General](#-arquitectura-general)
5. [Características Principales](#-características-principales)
6. [Mapa de Hotkeys](#-mapa-de-hotkeys-principales)
7. [Tecnologías y Dependencias](#-tecnologías-y-dependencias)
8. [Patrones de Diseño](#-patrones-de-diseño-observados)
9. [Flujo de Inicialización](#-flujo-de-inicialización)
10. [Sistema de Skills](#-comandos-y-skills)
11. [Casos de Uso Específicos](#-casos-de-uso-específicos)
12. [Conclusiones](#-conclusiones)
13. [Preguntas para Profundizar](#-preguntas-para-profundizar)

---

## Resumen Ejecutivo

Este es un **sistema de automatización personal avanzado** construido con AutoHotkey v2, diseñado para Windows. El proyecto implementa un framework sofisticado de productividad con múltiples subsistemas interconectados.

### Propósito Principal

**Automatización del flujo de trabajo diario** enfocado en:

1. **Gestión de Ventanas** - Sistema de bookmarks (favoritos) para acceso instantáneo a ventanas
2. **Gestión del Portapapeles** - Operaciones de copia/pegado optimizadas
3. **Ejecución de Programas** - Sistema ROA (Run or Activate) para lanzar/activar aplicaciones
4. **Menús de Aplicaciones** - Acceso rápido a todas las herramientas de trabajo
5. **Menús de Browsers** - Gestión de múltiples perfiles de navegadores (Vivaldi/Chrome)

### Proyecto Hermano: AI

Este proyecto trabaja en conjunto con otro ubicado en `c:\dev\ai` que maneja el procesamiento de prompts y diferentes modelos de IA. Este proyecto (`main`) se enfoca en la orquestación del entorno de trabajo, mientras que el proyecto AI maneja la interacción con modelos de lenguaje.

### Diagrama de Flujo de Trabajo

```
┌─────────────────────────────────────────────────────────────┐
│                    USUARIO PRESIONA HOTKEY                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
         Win+A           Win+W           Win+C
      (Aplicaciones)   (Browsers)      (Código)
            │               │               │
            └───────────────┴───────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │   Menu WebView System    │
              │  - Timeout keyboard nav  │
              │  - Fuzzy search GUI      │
              └────────────┬─────────────┘
                           │
                           ▼
                  ┌────────────────┐
                  │   ROA Engine   │
                  │ (Run or Activate)│
                  └────────┬───────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    Window Exists?    Launch App      Set Bookmark
          │                │                │
    ┌─────┴─────┐          │                │
    │           │          │                │
 Active?    Not Active     │                │
    │           │          │                │
Minimize   Activate    Wait & Track     Add to Map
    │           │          │                │
    └───────────┴──────────┴────────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │  Bookmark System        │
              │  - Save to config.ini   │
              │  - Update bookmarkMap   │
              └─────────────────────────┘
```

### Flujo de Integración con Proyecto AI

```
main.ahk (este proyecto)          c:\dev\ai (proyecto hermano)
┌───────────────────────┐         ┌──────────────────────────┐
│                       │         │                          │
│  Win+W → A            │────────▶│  Cursor IDE abre AI proj │
│  (hotkey)             │         │                          │
│                       │         │  - Prompts               │
│  Gestión de:          │         │  - Modelos               │
│  • Ventanas           │         │  - Flujos de IA          │
│  • Portapapeles       │◀────────│                          │
│  • Ejecución apps     │         │  Puede copiar al         │
│  • Bookmarks          │         │  clipboard para uso      │
│                       │         │  en main                 │
└───────────────────────┘         └──────────────────────────┘
```

---

## ⚡ Guía Rápida de Uso

### Para Empezar en 5 Minutos

1. **Menús principales** - Presiona y mantén:
   - `Win+A` = Aplicaciones (Spotify, Terminal, WhatsApp...)
   - `Win+W` = Navegadores y perfiles
   - `Win+C` = Proyectos de código

2. **Sistema de Bookmarks** - Tu herramienta más poderosa:
   ```
   Win+S → presiona cualquier tecla
   
   Si la ventana NO tiene bookmark → La marca
   Si la ventana YA tiene bookmark → La activa/minimiza
   ```

3. **Bookmarks directos** - Más rápido aún:
   ```
   Win+1 a Win+0    = Activa window #1 a #10
   Win+F            = Vivaldi Main (preconfigured)
   Win+G            = Vivaldi AI (preconfigured)
   Win+T            = Chat project
   ```

4. **Ver todos tus bookmarks:**
   ```
   Ctrl+Alt+Shift+B = Muestra GUI con todos los bookmarks
                      Presiona 1-9 para activar rápido
   ```

5. **Acceso al proyecto AI:**
   ```
   Win+W → A = Abre c:\dev\ai en Cursor
   ```

### Flujo de Trabajo Típico

```
Inicio del día:
1. Win+S → v → [Marca Vivaldi principal como 'V']
2. Win+S → c → [Marca Cursor como 'C']
3. Win+S → t → [Marca Terminal como 'T']

Durante el día:
• Win+S → v   = Vuelve a Vivaldi
• Win+S → c   = Vuelve a Cursor
• Win+S → t   = Vuelve a Terminal
• Win+W → A   = Abre proyecto AI
```

---

## 🏗️ Arquitectura General

### Estructura del Proyecto

```
main.ahk                 → Punto de entrada principal
├── lib/                 → Bibliotecas core reutilizables
│   ├── globals.ahk      → Variables globales centralizadas
│   ├── chord-hotkeys.ahk → Sistema de hotkeys multi-paso
│   ├── WebView2.ahk     → Integración WebView2
│   ├── audio.ahk        → Control de audio
│   ├── window.ahk       → Gestión de ventanas
│   ├── screen.ahk       → Utilidades de pantalla
│   ├── clipboard.ahk    → Gestión del portapapeles
│   ├── logging.ahk      → Sistema de logging
│   └── utils.ahk        → Utilidades generales
├── ui/                  → Interfaces HTML/CSS/JS para WebView
├── commands/            → Definiciones de comandos
├── skills/              → Módulos de skills extensibles
├── config.ini           → Configuración por máquina (no en git)
└── config.ini.dist      → Plantilla de configuración
```

### Módulos Principales

1. **init.ahk** - Inicialización del sistema
2. **functions.ahk** - Funciones core y gestión de configuración
3. **bookmarks.ahk** - Sistema de marcadores de ventanas
4. **menus.ahk** - Definiciones de menús
5. **menu-webview.ahk** - Motor de menús con WebView2
6. **hotkeys-global.ahk** - Hotkeys globales
7. **hotstrings.ahk** - Expansión de texto
8. **chrome.ahk** - Automatización de navegador
9. **system.ahk** - Utilidades del sistema
10. **code.ahk** - Automatización para VS Code/Cursor

---

## � Uso Principal del Sistema

### 1. Gestión de Ventanas con Bookmarks

El sistema de "favoritos" permite marcar ventanas y acceder a ellas instantáneamente:

**Ejemplo de uso:**
- `Win+S` → `a` → Marca la ventana actual como favorita "a"
- Presionar `Win+1` activa/minimiza la ventana marcada con ese número
- `Ctrl+Alt+Shift+B` muestra GUI con todas las ventanas marcadas

**Implementación clave:**
```ahk
; bookmarks.ahk - Sistema dinámico de bookmarks
bookmarks := [
  "#1", "#2", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#0",
  "#b", "#d", "#e", "#f", "#g", "#i", "#t", "#q", "#z", "#v", "#x",
  "!#a", "!#d", "!#e", "!#f", "!#g", "!#q", "!#r", "!#v", "!#x", "!#w", "!#z",
]
```

### 2. Gestión del Portapapeles

Operaciones optimizadas de portapapeles integradas en el flujo de trabajo:

**Funciones principales:**
```ahk
; lib/clipboard.ahk
ctrlC()                    ; Copia con validación
copyToClipboard(text)      ; Copia texto al portapapeles
```

**Ejemplo de integración:**
```ahk
; menus.ahk - Descarga de YouTube desde clipboard
DownloadYouTubeVideoFromClipboard() {
    url := A_Clipboard
    if (InStr(url, 'youtube.com')) {
        Run('c:\tools\ytd.bat "' . url . '"')
    }
}
```

### 3. Ejecución de Programas - Sistema ROA

**ROA = Run or Activate** - Si el programa está corriendo, lo activa; si no, lo ejecuta.

**Diagrama de Lógica ROA:**

```
Usuario ejecuta: Roa('spotify', 'spotify.exe')
                     │
                     ▼
         ┌───────────────────────┐
         │  ¿Existe la ventana?  │
         └──────────┬────────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
         SÍ                   NO
          │                   │
          ▼                   ▼
  ┌───────────────┐   ┌───────────────┐
  │ ¿Está activa? │   │ Ejecutar app  │
  └───────┬───────┘   └───────┬───────┘
          │                   │
    ┌─────┴─────┐             │
    │           │             ▼
   SÍ          NO      ┌──────────────┐
    │           │      │ Esperar hasta│
    ▼           ▼      │ que aparezca │
┌────────┐ ┌────────┐ └──────┬───────┘
│Minimize│ │Activate│        │
└────────┘ └────────┘        ▼
                      ┌──────────────┐
                      │Set Bookmark? │
                      └──────────────┘
```

**Implementación:**
```ahk
; roa.ahk - Función principal
Roa(alias, launchCommand, bookmark := false)
RoAWithPattern(winPattern, launchCmd, bookmark := false)
toggleOrLaunchApp(params)
```

**Variantes de ROA:**

1. **Roa()** - Búsqueda simple por alias
   ```ahk
   Roa('spotify', 'spotify.exe')
   ```

2. **RoAWithPattern()** - Búsqueda por patrón de ventana
   ```ahk
   RoAWithPattern('WhatsApp Beta', '"C:\...\whatsapp.exe"')
   ```

3. **toggleOrLaunchApp()** - Función genérica con callbacks
   ```ahk
   toggleOrLaunchApp({
       winPattern: 'ahk_exe notepad.exe',
       launchCmd: 'notepad.exe',
       matchMode: 'contains',
       timeout: 5000,
       onToggle: (hwnd, wasMinimized) => msg('Toggled!'),
       onLaunch: (hwnd) => msg('Launched!'),
       onError: (err) => msg('Error!')
   })
   ```

**Características avanzadas:**
- ✅ Búsqueda por bookmark primero (más rápido)
- ✅ Fallback a búsqueda por patrón
- ✅ Match modes: contains, exact, startsWith
- ✅ Extra validation con función custom
- ✅ Callbacks para eventos (toggle, launch, error)
- ✅ Timeout configurable para esperar ventana
- ✅ Logging opcional para debug

**Ejemplos de uso en menús:**
```ahk
; Abre Cursor en proyecto AI
Roa('ai-project', cursorExe . ' c:\dev\ai')

; Activa Spotify o lo ejecuta
Roa('spotify', 'spotify.exe')

; WhatsApp con patrón de búsqueda
RoAWithPattern('WhatsApp Beta', '"C:\Program Files\...\whatsapp.exe"')

; Con bookmark para acceso más rápido
Roa('vivaldi-main', vivaldiWithMainProfile, '#f')
```

### 4. Menús de Aplicaciones

**Hotkey:** `Win+A` → Menú principal de aplicaciones

```ahk
; menus.ahk - mainSeqA()
options := {
    waitml: 800,  // Espera 800ms por tecla, sino muestra GUI
    items: [
        { key: 'c', label: 'SpeedCrunch' },
        { key: 'f', label: 'File Explorer' },
        { key: 's', label: 'Spotify' },
        { key: 'w', label: 'WhatsApp' },
        { key: 't', label: 'tablet/telegram/terminal', items: [
            { key: 't', label: 'Windows Terminal' },
            { key: 'T', label: 'Telegram' },
            { key: 'a', label: 'Tablet' }
        ]},
        { key: 'x', label: 'XYplorer', items: [...] }
    ]
}
key := customMenuWebView(options)
```

**Características:**
- Si presionas `Win+A` → `s` rápidamente: ejecuta Spotify
- Si esperas: muestra menú gráfico con búsqueda fuzzy
- Soporta submenús (ej: `Win+A` → `t` → `t` = Terminal)

### 5. Menús de Browsers

**Hotkey:** `Win+W` → Menú de navegadores y profiles

```ahk
; menus.ahk - mainSeqW()
switch key {
    case 'f':
        Roa('vivaldi-main', vivaldiWithMainProfile, '#f')
    case 'g':
        Roa('vivaldi-ai', vivaldiWithAIProfile, '#g')
    case 'G':
        run(vivaldiWithGordosProfile)
    case 'v':
        Roa('vivaldi-youtube', vivaldiWithYoutubeProfile, '#v')
    case 'c':
        Roa('chrome-carnival', vivaldiWithCarnivalProfile)
    case 'd':
        run(chromeWithDebugProfile)
}
```

**Perfiles configurados:**
```ahk
; init.ahk - Múltiples perfiles de navegadores
vivaldiWithMainProfile := vivaldiExe ' --profile-directory="Profile 1"'
vivaldiWithAIProfile := vivaldiExe ' --profile-directory="AI"'
vivaldiWithYoutubeProfile := vivaldiExe ' --profile-directory="Youtube"'
vivaldiWithGordosProfile := vivaldiExe ' --profile-directory="Gordos"'
chromeWithWorkProfile := chromeExe ' --profile-directory="Work"'
chromeWithDebugProfile := chromeExe ' --remote-debugging-port=9222'
```

**Sitios específicos:**
```ahk
case 'sc':  // Win+W → S → C
    Roa('google-calendar', vivaldiWithMainProfile . ' https://calendar.google.com')
case 'sg':
    Roa('vivaldi-gemini', vivaldiWithGeminProfile . ' https://gemini.google.com/')
case 'sm':
    Roa('google-mail', vivaldiWithMainProfile . ' https://mail.google.com')
```

### 6. Integración con Proyecto AI

**Acceso rápido al proyecto hermano:**

```ahk
; menus.ahk - Win+W → A
case 'a':
    Roa('ai-project', cursorExe . ' c:\dev\ai')
```

**El proyecto AI (en `c:\dev\ai`):**
- Maneja procesamiento de prompts
- Integración con diferentes modelos de IA
- Este proyecto (`main`) lo referencia para acceso rápido

### 7. Menús de Código/IDEs

**Hotkey:** `Win+C` → Menú de editores y proyectos

```ahk
; menus.ahk - mainSeqC()
switch key {
    case 'M':
        Roa('main-scripts', cursorExe . ' c:\dev\scripts\main', '!m')
    case 's':
        Roa('scripts-folder', cursorExe . ' c:\dev\scripts', '!s')
    case 't':
        Roa('chat', cursorExe . ' c:\dev\chat', '#t')
    case 'c':
        Roa('cursor', cursorExe)
    case 'C':
        RoAWithPattern('ahk_exe Code.exe', vscodeExe, '^!c')
}
```

---

## �🌟 Características Principales

### 1. Sistema de Bookmarks de Ventanas
**Archivo:** `bookmarks.ahk`

- **Asignación Secuencial:** `Win+S` seguido de una tecla para crear/activar bookmarks
- **Asignación Directa:** Combinaciones predefinidas (Win+1-0, Win+F1-F6, Alt+1-0, etc.)
- **Persistencia:** Los bookmarks se guardan en `config.ini`
- **GUI de Gestión:** `Ctrl+Alt+Shift+B` muestra todos los bookmarks con búsqueda
- **Teclas de acceso rápido:** Números 1-9 en el GUI para activación instantánea

**Bookmarks predefinidos:**
- Win+1 a Win+0
- Win+B, D, E, F, G, I, T, Q, Z, V, X
- Alt+Win+A, D, E, F, G, Q, R, V, X, W, Z

### 2. Menús WebView2 Interactivos
**Archivo:** `menu-webview.ahk`

- **Navegación por teclado primero:** Si presionas una tecla dentro del timeout, ejecuta inmediatamente
- **Fallback a GUI:** Si no hay tecla presionada, muestra un picker WebView con filtrado fuzzy
- **Submenús:** Navegación con breadcrumbs
- **Retorno de combinaciones:** Devuelve cadenas como "sx1" para S→X→1
- **Navegación completa:** Flechas, Enter, Escape, Backspace para volver

### 3. Chord Hotkeys (Hotkeys Multi-Paso)
**Archivo:** `lib/chord-hotkeys.ahk`

Sistema de hotkeys de dos pasos tipo "Alt+Q → R" sin bloqueo:

```ahk
ChordRegister(prefixMap, executeFn)
```

- Timeout configurable (default: 0.9 seg)
- No bloquea el teclado durante la espera
- Ideal para crear combinaciones complejas sin conflictos

### 4. Sistema de Configuración Multi-Máquina
**Archivo:** `config.ini`

**Perfiles por computadora:**
- `[desktop]` - Máquina de escritorio
- `[work]` - Máquina de trabajo
- Detección automática basada en `A_ComputerName`

**Variables detectadas:**
```ini
isNotebook := A_ComputerName == 'ZENBOOK'
isRemote := A_ComputerName == 'CIDEV06'
isGordos := A_ComputerName == 'gordos'
isWork := A_ComputerName == 'AR-IT31927'
isCarnival := A_ComputerName == 'avdp-1310'
```

**Rutas configurables:**
- Aplicaciones (Chrome, VS Code, Cursor, Vivaldi, WhatsApp, etc.)
- Herramientas (nircmd, notifu, tail, XYplorer, StrokesPlus)
- Directorios base (dev, tools, scripts)

**Expansión de variables:** El sistema soporta variables tipo `%dev_dir%` en config.ini

### 5. Sistema de Skills Extensible
**Directorio:** `skills/`

Múltiples skills modulares:
- azure-devops-cli
- branch-namer
- claude-usage
- commit-changes
- cronjob-manager
- dev-browser
- feature-implementation
- google-calendar-skill
- jsdoc
- planning-protocol
- react-query-patterns
- whichkey-binding
- y muchos más...

### 6. Utilidades de Ventanas
**Archivo:** `lib/window.ahk`

Funciones para:
- Posicionamiento de ventanas
- Detección de monitores
- Minimizar a tray con NirCmd
- Gestión de aliases de ventanas
- Verificación de existencia de ventanas

### 7. Sistema de Logging
**Archivo:** `lib/logging.ahk`

- Función `msg()` para notificaciones visuales
- Logging a archivo configurable
- `emptylog()` para limpiar logs
- Visibility toggle con variable global `logVisibility`

### 8. Gestión de Clipboard Avanzada
**Archivo:** `lib/clipboard.ahk`

Funciones para manipulación del portapapeles con soporte para diferentes formatos.

### 9. Control de Audio
**Archivo:** `lib/audio.ahk`

Utilidades para control de volumen y dispositivos de audio.

### 10. Build System
**Archivo:** `build.bat`

Sistema de compilación automatizado:
1. Compila `main.ahk` a `main.exe`
2. Empaqueta archivos necesarios en `dist/`
3. Crea `main-automation-dist.zip` (versión portable)
4. Crea `main-automation-setup.exe` (instalador con Inno Setup)

---

## 🔧 Tecnologías y Dependencias

### Runtime
- **AutoHotkey v2.0+** (requerido para desarrollo)
- **Windows 10/11**
- **WebView2 Runtime** (generalmente preinstalado)

### Herramientas de Desarrollo
- **Ahk2Exe** - Compilador de AutoHotkey
- **Inno Setup 6.x** - Para crear instalador (opcional)

### Herramientas Externas Configurables
- **nircmd.exe** - Utilidades de línea de comandos
- **notifu.exe** - Notificaciones
- **Tail.exe** - Visualización de logs
- **StrokesPlus.net** - Gestos de mouse
- **XYplorer** - Gestor de archivos

---

## 📋 Archivo de Configuración

### Secciones Principales

```ini
[paths]
; Rutas del sistema (actualizadas en inicialización)
user_home=
user_documents=
user_appdata=
program_files=

[general]
lastDate=

[variables]
cursorKeysEnabled=1
logVisibility=0

[appInstances]
; Mapeo de instancias de aplicaciones

[bookmarks]
; Bookmarks de ventanas persistentes

[desktop] / [work]
; Configuración específica por máquina
```

---

## 🎯 Funcionalidades Destacadas

### Recarga Automática
El sistema monitorea cambios en archivos clave y recarga automáticamente:

```ahk
filesToCheckForReload := [
  {path: './main.ahk', lastModVar: ...},
  {path: './functions.ahk', lastModVar: ...},
  // ... más archivos
]
```

### Detección de Administrador
Advierte si se ejecuta como administrador (no recomendado):

```ahk
if(A_IsAdmin){
  MsgBox('Better not to run this as Administrator!!')
}
```

### Perfiles de Navegador Múltiples
Configuración de múltiples perfiles de Vivaldi y Chrome:

```ahk
vivaldiWithMainProfile := vivaldiExe ' --profile-directory="Profile 1"'
vivaldiWithCarnivalProfile := vivaldiExe ' --profile-directory="Carnival"'
vivaldiWithAIProfile := vivaldiExe ' --profile-directory="AI"'
chromeWithWorkProfile := chromeExe ' --profile-directory="Work"'
```

### Función ROA (Run Or Activate)
**Archivo:** `roa.ahk`

Sistema de alias para ventanas que permite:
- Ejecutar una aplicación si no está corriendo
- Activar la ventana si ya existe
- Gestionar múltiples instancias con aliases

### Hotstrings (Expansión de Texto)
**Archivo:** `hotstrings.ahk`

Sistema de abreviaciones que se expanden automáticamente al escribir.

---

## 🔍 Patrones de Diseño Observados

### 1. Modularización
- Separación clara entre bibliotecas (`lib/`), UI (`ui/`), y lógica de negocio
- Cada módulo tiene responsabilidad única
- Sistema de includes para composición

### 2. Configuración sobre Código
- Máxima flexibilidad a través de `config.ini`
- Soporte multi-máquina sin cambios de código
- Variables de entorno expandibles

### 3. Caché de Configuración
```ahk
global configCache := Map()  ; Cache para reducir I/O
GetCachedConfig(section, key, default := "")
```

### 4. Mapeos Globales
```ahk
global appInstanceMap := Map()  ; Tracking de instancias
global aliasMap := Map()        ; Gestión de ventanas por alias
global bookmarkMap := Map()     ; Sistema de bookmarks
```

### 5. Funciones Optional Parameters
Uso extensivo de parámetros opcionales con valores por defecto:
```ahk
IniReadWithExpansion(section, key, defaultValue := "")
msg(text, options := {})
```

---

## 🚀 Flujo de Inicialización

1. **main.ahk**
   - Configura hooks de teclado y mouse
   - Verifica si no es admin
   - Include de todas las bibliotecas

2. **lib/globals.ahk**
   - Declara variables globales
   - Detecta tipo de máquina (notebook, remote, work, etc.)

3. **init.ahk**
   - Carga aliasMap desde config.ini
   - Lee rutas de aplicaciones según deviceSection
   - Valida existencia de rutas con `CheckConfigPaths()`
   - Inicializa variables persistentes
   - Ejecuta StrokesPlus.net si no está corriendo
   - Llama a `onceADay()` para tareas diarias
   - Llama a `emptylog()` para limpiar log

4. **Carga de módulos funcionales**
   - bookmarks.ahk → Sistema de marcadores
   - menus.ahk → Definiciones de menús
   - hotkeys-global.ahk → Hotkeys globales
   - etc.

---

## 📝 Comandos y Skills

### Estructura de Commands
**Directorio:** `commands/`

Archivos markdown con documentación de comandos personalizados.

### Estructura de Skills
**Directorio:** `skills/`

Cada skill es un subdirectorio con:
- Archivos de configuración
- Scripts auxiliares
- Documentación
- Recursos específicos

**Skills notables:**
- `azure-devops-cli/` - Integración con Azure DevOps
- `branch-namer/` - Nombrado automático de ramas
- `commit-changes/` - Gestión de commits
- `google-calendar-skill/` - Integración con Google Calendar
- `jsdoc/` - Generación de documentación JSDoc
- `pr/` - Gestión de Pull Requests
- `us-*` - Serie de skills relacionados con User Stories

---

## 🎨 UI y WebView2

### Arquitectura de UI
**Directorio:** `ui/`

```
ui/
└── menu.html    → Template HTML para menús WebView
```

### WebViewToo.ahk
**Archivo:** `lib/WebViewToo.ahk`

Wrapper mejorado de WebView2 que proporciona:
- Comunicación bidireccional JavaScript ↔ AHK
- Manejo de eventos
- Gestión de lifecycle de ventanas WebView

---

## 🐛 Sistema de Debug

### Variables de Toggle
```ahk
global toggleCodeDebug := false
global toggleChromeDebug := false
global toggleObsidanDebug := false
```

### Perfiles de Debug
```ahk
chromeWithDebugProfile := chromeExe ' --profile-directory="Profile 3" --user-data-dir="c:\chrome-debug" --remote-debugging-port=9222'
vivaldiWithDebugProfile := vivaldiExe ' --profile-directory="Debug" --remote-debugging-port=9222'
```

---

## 📦 Sistema de Distribución

### Versión Portable
`main-automation-dist.zip` contiene:
- main.exe
- lib/ (bibliotecas)
- ui/ (archivos de interfaz)
- config.ini.dist (plantilla)
- Archivos auxiliares

### Instalador
`main-automation-setup.exe` creado con Inno Setup (`installer.iss`):
- Instalación guiada
- Opción de inicio con Windows
- Configuración automática del sistema

---

## 🔑 Mapa de Hotkeys Principales

### Menús Principales

| Hotkey | Función | Descripción |
|--------|---------|-------------|
| `Win+A` | **Apps Menu** | Menú de aplicaciones (Spotify, Terminal, WhatsApp, XYplorer, etc.) |
| `Win+W` | **Web/Browsers Menu** | Menú de navegadores y perfiles (Vivaldi, Chrome, sitios frecuentes) |
| `Win+C` | **Code Menu** | Menú de editores y proyectos (Cursor, VSCode, carpetas de proyectos) |

### Sistema de Bookmarks

| Hotkey | Función | Descripción |
|--------|---------|-------------|
| `Win+S` → `[tecla]` | **Crear/Activar Bookmark** | Secuencial: asigna ventana actual o activa bookmarked |
| `Win+Shift+S` → `[tecla]` | **Reasignar Bookmark** | Fuerza reasignación de bookmark |
| `Win+1` a `Win+0` | **Bookmarks Directos** | Activar/minimizar ventanas marcadas |
| `Win+Shift+1` a `Win+Shift+0` | **Asignar Directamente** | Asigna ventana actual a ese número |
| `Ctrl+Alt+Shift+B` | **GUI Bookmarks** | Muestra todos los bookmarks con búsqueda |
| `Win+Alt+Ctrl+B` | **Gestión Bookmarks** | Menú de configuración (mostrar, limpiar, recargar) |

### Bookmarks Predefinidos por Letra

| Combinación | Uso Típico | Combinación | Uso Típico |
|------------|-----------|------------|-----------|
| `Win+B` | Bookmark B | `Win+D` | Bookmark D |
| `Win+E` | Bookmark E | `Win+F` | Vivaldi Main (por defecto) |
| `Win+G` | AI Browser | `Win+I` | Bookmark I |
| `Win+T` | Chat/Terminal | `Win+Q` | Bookmark Q |
| `Win+Z` | Bookmark Z | `Win+V` | Youtube Browser |
| `Win+X` | Bookmark X | | |

### Bookmarks Alt+Win

| Combinación | Descripción |
|------------|-----------|
| `Alt+Win+A` a `Alt+Win+Z` | 11 bookmarks adicionales con Alt+Win |

### Utilidades Globales

| Hotkey | Función | Descripción |
|--------|---------|-------------|
| `Alt+F1` | **Minimizar a Tray** | Minimiza ventana activa al systray con NirCmd |
| `Ctrl+F12` | **Mouse Position** | Muestra posición Y del mouse (debug) |

### Chrome/Vivaldi Específicos

| Hotkey | Función | Solo en Chrome/Vivaldi |
|--------|---------|----------------------|
| `Alt+B` | **Star Search** | Ctrl+L + "* " (búsqueda con marcador) |
| `Alt+E` | **Developer Tools** | Abre F8 |
| `Alt+A` | **Back** | Navega atrás (Alt+Left) |
| `Alt+S` | **Forward** | Navega adelante (Alt+Right) |
| `F8` | **Set Browser Title** | Establece título custom del navegador |

### Accesos Rápidos Específicos

#### Win+W (Browsers)
- `Win+W` → `F` = Vivaldi Main Profile
- `Win+W` → `G` = Vivaldi AI Profile  
- `Win+W` → `V` = Vivaldi Youtube Profile
- `Win+W` → `A` = **Proyecto AI en Cursor** (`c:\dev\ai`)
- `Win+W` → `C` = Chrome Carnival Profile
- `Win+W` → `D` = Chrome Debug Mode
- `Win+W` → `S` → `C` = Google Calendar
- `Win+W` → `S` → `G` = Gemini
- `Win+W` → `S` → `M` = Gmail
- `Win+W` → `Y` → `V` = Download YouTube Video
- `Win+W` → `Y` → `A` = Download YouTube Audio

#### Win+A (Apps)
- `Win+A` → `S` = Spotify
- `Win+A` → `W` = WhatsApp
- `Win+A` → `F` = File Explorer
- `Win+A` → `C` = SpeedCrunch (calculadora)
- `Win+A` → `T` → `T` = Windows Terminal
- `Win+A` → `T` → `W` = Warp Terminal
- `Win+A` → `T` → `T` (mayúscula) = Telegram
- `Win+A` → `X` → `X` = XYplorer
- `Win+A` → `X` → `D` = XYplorer en carpeta Dev
- `Win+A` → `#B` = Show Bookmarks GUI

#### Win+C (Code)
- `Win+C` → `M` = Main Scripts en Cursor
- `Win+C` → `S` = Scripts Folder en Cursor
- `Win+C` → `T` = Chat Project (`c:\dev\chat`)
- `Win+C` → `C` = Cursor (ejecutable)
- `Win+C` (mayúscula) = VS Code

---

## 🎭 Casos de Uso Específicos

### 1. Gestión de Ventanas Multi-Monitor
El sistema detecta automáticamente monitores y posiciona ventanas.

### 2. Automatización de Trading/Algo
Menús específicos para StrategyQuant y herramientas de trading algorítmico.

### 3. Desarrollo Multi-IDE
Soporte para VS Code, Cursor, y múltiples editores.

### 4. Navegación Multi-Perfil
Gestión de múltiples perfiles de navegador para diferentes contextos (trabajo, personal, AI, etc.).

### 5. Integración con Herramientas de Productividad
- Spotify
- Telegram
- Terminal (Windows Terminal, Warp)
- WhatsApp
- XYplorer
- ShareX

---

## 📚 Archivos de Documentación

### Principales
- `README.md` - Documentación general del proyecto
- `bookmarks.md` - Documentación completa del sistema de bookmarks (referenciado pero no incluido)
- Archivos en `commands/` - Documentación de comandos específicos

### Archivados
**Directorio:** `Archived/`

Archivos históricos y experimentales:
- `portability-summary.md` - Resumen de portabilidad
- Módulos deprecados (discord.ahk, teams.ahk, etc.)
- Configs antiguas

---

## 🔐 Seguridad y Buenas Prácticas

### 1. config.ini no está en Git
La configuración real con rutas personales no se versiona, solo `config.ini.dist`.

### 2. Verificación de Rutas
```ahk
CheckConfigPaths(deviceSection)
```
Valida que todas las rutas configuradas existan al iniciar.

### 3. No Ejecutar como Admin
El script advierte si se ejecuta con privilegios elevados.

### 4. Persistencia Segura
Los bookmarks se persisten en `config.ini` con manejo de errores.

---

## 🔮 Tecnologías Avanzadas Utilizadas

### 1. InputHook
Para captura avanzada de teclas sin bloqueo.

### 2. CoordMode
Configuración precisa de coordenadas de mouse.

### 3. SetTimer
Para verificaciones periódicas y recarga automática.

### 4. OnExit
Manejo de cleanup al cerrar el script.

### 5. ImageSearch
Búsqueda de imágenes en pantalla para automatización visual.

### 6. COM y WebView2
Integración de controles web modernos en GUI de AHK.

---

## 🎓 Conceptos Aprendibles del Código

### 1. Sistema de Menús Progresivos
Combinación inteligente de navegación por teclado + GUI fallback.

### 2. Gestión de Estado Global
Uso de Maps globales para tracking de estado.

### 3. Caché de Configuración
Reducción de I/O mediante caché en memoria.

### 4. Chord Hotkeys
Implementación de hotkeys multi-paso sin bloqueo.

### 5. Sistema de Build Automatizado
Script .bat que compila, empaqueta y crea instalador.

### 6. Arquitectura Modular en AHK
Organización enterprise-grade de código AutoHotkey.

---

## ⚠️ Áreas que Requieren Atención

### 1. Rutas Hardcodeadas
Algunas rutas como perfiles de Vivaldi están hardcodeadas:
```ahk
vivaldiWithCarnivalProfile := vivaldiExe ' --user-data-dir="C:\tools\vivaldi\User Data"'
```

### 2. Dependencias de Herramientas Externas
El sistema depende de herramientas específicas (nircmd, notifu, etc.) que deben estar instaladas.

### 3. Documentación de Skills
Muchos skills tienen poca documentación sobre su uso específico.

### 4. Paths de Compilador Hardcodeados
En `build.bat`:
```bat
set "AHK_COMPILER=C:\Users\jsa6055\AppData\Local\Programs\AutoHotkey\Compiler\Ahk2Exe.exe"
```

---

## 🎯 Conclusiones

Este es un **framework de automatización muy maduro y sofisticado** que demuestra:

1. **Arquitectura Enterprise:** Modularización, separación de concerns, configuración centralizada
2. **UX Avanzada:** Sistema de menús híbrido teclado/GUI, bookmarks persistentes
3. **Extensibilidad:** Sistema de skills pluggable
4. **Portabilidad:** Soporte multi-máquina con perfiles
5. **Developer Experience:** Auto-reload, logging, debugging
6. **Productividad:** Integración profunda con herramientas diarias

### Fortalezas
- ✅ Código bien organizado y modular
- ✅ Sistema de configuración robusto
- ✅ Buenas prácticas de AutoHotkey v2
- ✅ Documentación presente
- ✅ Sistema de build automatizado

### Áreas de Mejora
- ⚠️ Algunas rutas hardcodeadas
- ⚠️ Dependencias externas no documentadas completamente
- ⚠️ Algunos módulos en Archived/ podrían necesitar limpieza

---

## 📞 Preguntas para Profundizar

### Sobre el Proyecto AI
1. **¿Qué hace exactamente el proyecto AI en `c:\dev\ai`?** ¿Es un sistema de prompts template, un wrapper de APIs, o algo más complejo?

2. **¿Los dos proyectos se comunican entre sí?** ¿O solo este proyecto (`main`) abre el de AI con Cursor?

3. **¿Usas el mismo sistema de menús WebView en el proyecto AI?** ¿O son arquitecturas completamente diferentes?

### Sobre el Uso Diario
4. **¿Cuál es tu flujo de trabajo típico?** Por ejemplo: ¿Abres todo con bookmarks por la mañana, o vas abriendo según necesitas?

5. **¿Los perfiles de navegador responden a contextos específicos?** (ej: ¿"Carnival" es para diversión, "AI" para trabajo con IAs, etc.?)

6. **¿Qué skills usas más frecuentemente?** De los 40+ que hay en el directorio `skills/`

### Sobre Funcionalidades Específicas
7. **El sistema de chord-hotkeys, ¿lo usas activamente?** No vi muchas definiciones en el código.

8. **¿Los archivos en `Archived/` son para mantener o podemos limpiar?** (discord.ahk, teams.ahk, etc.)

9. **¿Las imágenes referenciadas (`rename.png`, `clear-all.png`) están en algún lado?** No las vi en la estructura.

### Sobre Mejoras Futuras
10. **¿Hay algo que quieras mejorar o automatizar mejor?** ¿Algún flujo que todavía te resulte tedioso?

11. **¿Consideraste usar el proyecto AI desde este script?** Por ejemplo, enviar comandos o prompts directamente sin cambiar de ventana.

12. **¿Te interesaría hacer el sistema más portable** para compartir con otros o usar en múltiples máquinas más fácilmente?

---

**✅ Confirmado del Código:**
- ✅ Uso principal: Ventanas, portapapeles, ejecución de programas
- ✅ Menús: Aplicaciones (`Win+A`), Browsers (`Win+W`), Código (`Win+C`)
- ✅ Bookmarks: Sistema completo con 30+ combinaciones predefinidas
- ✅ ROA: Función core usada en todos los menús
- ✅ Proyecto AI: Ubicado en `c:\dev\ai`, accesible vía `Win+W → A`
- ✅ Perfiles múltiples: Main, AI, Youtube, Gordos, Carnival, Work, Debug

---

**Autor del Análisis:** GitHub Copilot  
**Fecha:** 23 de Febrero de 2026  
**Versión del Proyecto Analizada:** Snapshot actual
