# Guía: Portabilidad y Manejo de Paths

**Fecha:** 23 de febrero de 2026  
**Commits:** lib/path-validator.ahk, init.ahk, roa.ahk modificados

---

## ¿El Problema Resuelto?

Cuando instalás el script en **otra PC**, los paths hardcodeados en `config.ini` no existen (C:\tools\nircmd.exe, C:\Program Files\Cursor\Cursor.exe, etc.). 

**Antes:** El script mostraba errores crípticos o directamente se cerraba.  
**Ahora:** El script detecta automáticamente, pregunta al usuario, y funciona con lo que esté disponible.

---

## 🔧 Cómo Funciona el Sistema

### 1. Auto-Detección de Paths

El script busca aplicaciones en **ubicaciones comunes**:

```
Chrome:
  - C:\Program Files\Google\Chrome\Application\chrome.exe
  - C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
  - %LocalAppData%\Google\Chrome\Application\chrome.exe
  
VS Code:
  - %LocalAppData%\Programs\Microsoft VS Code\Code.exe
  - C:\Program Files\Microsoft VS Code\Code.exe
  
Cursor, Vivaldi, XYplorer, NirCmd: similar logic
```

Si encuentra el archivo, **lo guarda automáticamente** en config.ini.

### 2. Validación en Startup

Al iniciar, [init.ahk](init.ahk#L21-L30) valida **todos los paths configurados**:

```ahk
cursorExe := ValidatePath(deviceSection, "cursor_path", "Cursor", false, GetCommonPaths("cursor"))
```

**Parámetros:**
- `"cursor_path"` - Key en config.ini
- `"Cursor"` - Nombre user-friendly para diálogos
- `false` - No es crítico (el script funciona sin esto)
- `GetCommonPaths("cursor")` - Array de ubicaciones comunes

### 3. Diálogo Resumen

Si faltan paths, muestra **un solo diálogo** al inicio:

```
╔═════════════════════════════════════════════╗
║  Algunas aplicaciones no fueron encontradas  ║
╚═════════════════════════════════════════════╝

⚠ OPCIONALES (features deshabilitadas):
  • Cursor
  • XYplorer
  • NirCmd

Podés configurarlas más tarde editando:
C:\Program Files\Main Automation\config.ini

El script funcionará con las aplicaciones disponibles.
```

**No bloquea el inicio** - solo informa.

### 4. Manejo en Runtime

Cuando intentás usar una aplicación que no está configurada:

```
Hotkey: Win+C (lanzar Cursor en c:\dev\ai)
   ↓
Roa() intenta lanzar cursorExe
   ↓
cursorExe = "" (vacío porque no fue encontrado)
   ↓
Muestra: "Aplicación no encontrada: C:\Program Files\cursor\Cursor.exe"
```

**Sin crashes, sin errores de sistema**, solo mensajes claros.

---

## 📂 Paths Críticos vs Opcionales

| Path | Tipo | Si falta... |
|------|------|-------------|
| **Aplicaciones** (Cursor, VS Code, Chrome, Vivaldi, etc.) | Opcional | Features deshabilitadas, script funciona |
| **NirCmd** | Opcional | Usa `WinMinimize()` normal en lugar de minimize-to-tray |
| **XYplorer** | Opcional | No podés lanzar con ese file manager |
| **config.ini** | Crítico | Se crea automáticamente desde config.ini.dist |

**Filosofía:** El script funciona con **lo que tenés**, no fuerza dependencias.

---

## 🛠️ Configuración para Nueva PC

### Opción 1: Automática (Recomendada)

1. Instalá/ejecutá el script
2. El sistema detecta automáticamente Chrome, VS Code, Cursor, etc.
3. Te muestra qué no encontró
4. **Listo** - funciona con lo detectado

### Opción 2: Manual (Ubicaciones Custom)

Si tus aplicaciones están en paths no estándar:

```ini
[desktop]
cursor_path=D:\Apps\Cursor\Cursor.exe
nircmd_exe=E:\PortableTools\nircmd.exe
```

Si dejás **vacío**, el script intenta auto-detectar en el próximo inicio.

### Opción 3: Interactiva (Primera Vez)

Para paths críticos que no se auto-detectan, el script pregunta:

```
╔═══════════════════════════════════════════╗
║  Path no encontrado                       ║
╚═══════════════════════════════════════════╝

El path configurado para Cursor no existe:
C:\Program Files\cursor\Cursor.exe

Por favor, seleccioná la ubicación correcta.

[📁 Seleccionar archivo...]  [Cancelar]
```

---

## 🐛 Manejo de Errores

### Ejemplo 1: Path Configurado Pero Archivo Movido

**Antes:**
```
Error en línea 42: Run() - archivo no encontrado
C:\tools\vivaldi\Application\vivaldi.exe
```

**Ahora:**
```
Aplicación no encontrada: C:\tools\vivaldi\Application\vivaldi.exe
(3 segundos, desaparece automáticamente)
```

### Ejemplo 2: Intentando Usar Feature Sin Path

**Antes:**
```
Run("") - comando inválido
Error: The system cannot find the file specified.
```

**Ahora:**
```
No se puede lanzar: path no configurado
(3 segundos, continúa sin crash)
```

### Ejemplo 3: NirCmd No Disponible

**Antes:**
```
Error: Missing nircmd path in config.ini
[Script se detiene]
```

**Ahora:**
```
NirCmd no está disponible.

Para usar esta función, instalá NirCmd y configurá 
su path en config.ini.

Por ahora, se minimizará la ventana normalmente.

[OK]
```

Ejecuta fallback: `WinMinimize()` en lugar de minimize-to-tray.

---

## 📝 Archivos Modificados

### [lib/path-validator.ahk](lib/path-validator.ahk) (NUEVO)

**Funciones principales:**

- `ValidatePath()` - Valida, auto-detecta, o pregunta por path
- `AutoDetectPath()` - Busca en ubicaciones comunes
- `PromptForPath()` - Muestra file picker al usuario
- `GetCommonPaths()` - Devuelve array de ubicaciones estándar
- `ShowMissingPathsSummary()` - Diálogo resumen de paths faltantes

### [init.ahk](init.ahk) (MODIFICADO)

**Cambios:**

```diff
- whatsappExe := IniRead("config.ini", deviceSection, "whatsapp_path", "")
+ whatsappExe := ValidatePath(deviceSection, "whatsapp_path", "WhatsApp", false)

- if (!whatsappExe || !cursorExe || ...) {
-     MsgBox("Error: Missing required paths...")
-     ExitApp(1)
- }
+ ; Eliminado - ya no cierra el script por paths faltantes
```

**Resultado:** Validación flexible que no bloquea el inicio.

### [roa.ahk](roa.ahk) (MODIFICADO)

**Cambios:**

```diff
  if (!found) {
+     ; Validar que launchCmd no esté vacío
+     if (!params.launchCmd || params.launchCmd = "") {
+         msg('No se puede lanzar: path no configurado', { seconds: 3 })
+         return false
+     }
+     
+     ; Validar que el ejecutable exista
+     if (!FileExist(exePath)) {
+         msg('Aplicación no encontrada: ' . exePath, { seconds: 3 })
+         return false
+     }
      
      Run(params.launchCmd)
  }
```

**Resultado:** Mensajes claros en lugar de crashes.

### [lib/window.ahk](lib/window.ahk) (MODIFICADO)

**Cambios:**

```diff
  MinimizeToTrayWithNirCmd(winTitle) {
      nircmdExe := GetCachedConfig("desktop", "nircmd_exe", "")
-     if (!nircmdExe) {
-         msgV1("Error: Missing nircmd path in config.ini", 3)
-         return
-     }
+     if (!nircmdExe || !FileExist(nircmdExe)) {
+         MsgBox("NirCmd no está disponible...")
+         WinMinimize(winTitle)  ; Fallback
+         return
+     }
      Run(nircmdExe . ' win min title "' . winTitle . '"')
  }
```

**Resultado:** Fallback gracioso a WinMinimize() normal.

### [config.ini.dist](config.ini.dist) (MODIFICADO)

**Cambios:**

- Agregados comentarios explicativos sobre auto-detección
- Marcados paths como opcionales
- Indicado que dejándolos vacíos se auto-detectan

---

## 🎯 Testing en Nueva PC

### Escenario 1: PC sin ninguna app instalada

```
Resultado: 
✓ Script inicia correctamente
✓ Muestra diálogo con lista de apps no encontradas
✓ Todas las features requiriendo esas apps están deshabilitadas
✓ Hotkeys siguen funcionando
✓ Menu-webview funciona (no requiere apps externas)
```

### Escenario 2: Solo Chrome instalado

```
Resultado:
✓ Auto-detecta Chrome en C:\Program Files\Google\Chrome\...
✓ Guarda path en config.ini
✓ Features de Chrome funcionan
✓ Otras features deshabilitadas
```

### Escenario 3: Todo instalado pero en paths custom

```
Resultado:
✓ No encuentra en ubicaciones estándar
✓ Muestra diálogo: "Path no encontrado, seleccioná ubicación"
✓ Usuario selecciona manualmente
✓ Guarda en config.ini para próximos inicios
```

---

## 💡 Beneficios

1. **Portabilidad total** - Funciona en cualquier PC sin setup manual
2. **Sin crashes** - Errores claros en lugar de exceptions de sistema
3. **Auto-configuración** - Detecta automáticamente ubicaciones comunes
4. **Degradación elegante** - Features faltantes no rompen el resto
5. **User-friendly** - Mensajes claros, no errores técnicos
6. **Zero-config ideal** - En el mejor caso, todo se auto-detecta

---

## 📖 Para el Usuario Final

### Primera Instalación

1. Ejecutá `main-automation-setup.exe`
2. Si aparece diálogo de apps faltantes, leelo y clickeá OK
3. Empezá a usar el script
4. Si intentás usar una feature no disponible, te dirá claramente qué falta

### Configurar Path Manualmente

1. Abrí: `C:\Program Files\Main Automation\config.ini`
2. Encontrá la sección `[desktop]` o `[work]` (según tu PC)
3. Agregá el path:
   ```ini
   cursor_path=D:\Apps\Cursor\Cursor.exe
   ```
4. Guardá y reiniciá el script

### Verificar Qué Está Configurado

No hay comando aún - próxima feature: `Win+Alt+P` para ver status de paths.

---

**Conclusión:** El script ahora es completamente portable, se auto-configura, y maneja errores de manera user-friendly sin crashes ni mensajes crípticos.
