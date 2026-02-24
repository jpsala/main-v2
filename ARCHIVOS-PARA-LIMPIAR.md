# Archivos y Carpetas para Limpiar

## ✅ LIMPIEZA COMPLETADA - 23 de Febrero de 2026

**Estado:** Limpieza exitosa - ~1 GB y 43,000+ archivos eliminados

**Commits:**
- `dc4485f` - Análisis y documentación pre-limpieza
- `b84b40e` - Limpieza masiva completada

**Backup local:** `_backup_20260223_212517/` (no versionado en git)

---

## 📊 Resumen de lo Eliminado

### ❌ NO REFERENCIADOS en código (Candidatos para eliminar)

#### 📁 Directorios
| Directorio | Tamaño estimado | Referenciado | Acción recomendada |
|-----------|-----------------|--------------|-------------------|
| `skills/` | ~40+ subdirectorios | ❌ No | **ELIMINAR** - No se utiliza en ningún include ni referencia |
| `commands/` | Varios markdown | ❌ No | **ELIMINAR** - No está incluido en main.ahk |
| `.skills/` | Desconocido | ❌ No | **ELIMINAR** - Hidden folder no referenciado |
| `Archived/` | ~13 archivos | ❌ No | **ELIMINAR** - Archivos deprecados |

#### 📄 Archivos en root
| Archivo | Usado | Acción recomendada |
|---------|-------|-------------------|
| `menu-webview-example.ahk` | ❌ No | **ELIMINAR** - Ejemplo no usado |
| `cleanup-config.ps1` | ❌ No | **EVALUAR** - ¿Script útil? |
| `bookmarks-missing.txt` | ❌ No | **ELIMINAR** - Log temporal |
| `missing-paths.log` | ❌ No | **ELIMINAR** - Log que se regenera |
| `wrench.png` | ❌ No | **ELIMINAR** - Imagen no referenciada |
| `log.txt` | ❌ No | **ELIMINAR** - Log que se regenera |

### ✅ REFERENCIADOS en código (Mantener)

#### 📁 Directorios en uso
- `lib/` - ✅ Todas las bibliotecas están incluidas en main.ahk
- `ui/` - ✅ Usado por sistema de menús WebView2
- `.git/` - ✅ Control de versiones
- `.vscode/` - ✅ Configuración del editor
- `dist/` - ✅ Output del build (ignorado en git)

#### 📄 Archivos principales en uso
- `main.ahk` - ✅ Punto de entrada
- `bookmarks.ahk` - ✅ Sistema de bookmarks
- `chrome.ahk` - ✅ Automatización de Chrome
- `code.ahk` - ✅ Automatización de VS Code/Cursor
- `functions.ahk` - ✅ Funciones core
- `hotkeys-global.ahk` - ✅ Hotkeys globales
- `hotstrings.ahk` - ✅ Expansión de texto
- `init.ahk` - ✅ Inicialización
- `menu.ahk` - ✅ Sistema de menús legacy
- `menu-webview.ahk` - ✅ Sistema de menús WebView2
- `menus.ahk` - ✅ Definiciones de menús
- `msg.ahk` - ✅ Sistema de mensajes
- `roa.ahk` - ✅ Sistema Run or Activate
- `system.ahk` - ✅ Utilidades del sistema

#### 📄 Archivos de configuración y build
- `build.bat` - ✅ Script de compilación
- `config.ini` - ✅ Config personal (ignorado en git)
- `config.ini.dist` - ✅ Template de configuración
- `installer.iss` - ✅ Script de instalador
- `main.ico` / `icon.ico` - ✅ Iconos
- `.gitignore` - ✅ Config de git
- `README.md` - ✅ Documentación
- `ANALISIS-PROYECTO.md` - ✅ Análisis técnico

---

## 🗑️ Plan de Limpieza Recomendado

### Fase 1: Archivos Temporales (Seguro)
```powershell
# Logs y archivos temporales que se regeneran
Remove-Item "bookmarks-missing.txt" -ErrorAction SilentlyContinue
Remove-Item "missing-paths.log" -ErrorAction SilentlyContinue
Remove-Item "log.txt" -ErrorAction SilentlyContinue
```

### Fase 2: Ejemplos No Usados (Seguro)
```powershell
# Archivo de ejemplo no utilizado
Remove-Item "menu-webview-example.ahk" -ErrorAction SilentlyContinue
```

### Fase 3: Imágenes No Referenciadas (Revisar primero)
```powershell
# Imagen no encontrada en el código
# REVISAR: ¿Se usa en hotkeys-global.ahk para ImageSearch?
Remove-Item "wrench.png" -ErrorAction SilentlyContinue
Remove-Item "rename.png" -ErrorAction SilentlyContinue -ErrorAction SilentlyContinue
Remove-Item "clear-all.png" -ErrorAction SilentlyContinue
```

### Fase 4: Directorios No Utilizados (IMPORTANTE: Backup primero)
```powershell
# BACKUP primero por si acaso
Copy-Item "skills" "skills_backup_$(Get-Date -Format 'yyyyMMdd')" -Recurse -ErrorAction SilentlyContinue
Copy-Item "commands" "commands_backup_$(Get-Date -Format 'yyyyMMdd')" -Recurse -ErrorAction SilentlyContinue
Copy-Item ".skills" ".skills_backup_$(Get-Date -Format 'yyyyMMdd')" -Recurse -ErrorAction SilentlyContinue
Copy-Item "Archived" "Archived_backup_$(Get-Date -Format 'yyyyMMdd')" -Recurse -ErrorAction SilentlyContinue

# Luego eliminar
Remove-Item "skills" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "commands" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".skills" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "Archived" -Recurse -Force -ErrorAction SilentlyContinue
```

### Fase 5: Scripts de Utilidad (Evaluar)
```powershell
# Revisar si cleanup-config.ps1 es útil antes de eliminar
# Si no lo usas, eliminar:
Remove-Item "cleanup-config.ps1" -ErrorAction SilentlyContinue
```

---

## 📝 Verificación en Código

### Búsquedas realizadas:
```ahk
# No se encontraron referencias a:
grep -r "skills" *.ahk        # No matches
grep -r "commands" *.ahk      # No matches
grep -r "Archived" *.ahk      # No matches
grep -r ".skills" *.ahk       # No matches
```

### Includes en main.ahk (todos están en uso):
```ahk
#Include 'lib\globals.ahk'          ✅
#Include 'lib\chord-hotkeys.ahk'    ✅
#Include 'lib\audio.ahk'            ✅
#Include 'lib\window.ahk'           ✅
#Include 'lib\screen.ahk'           ✅
#Include 'lib\clipboard.ahk'        ✅
#Include 'lib\logging.ahk'          ✅
#Include 'lib\utils.ahk'            ✅
#Include '.\msg.ahk'                ✅
#Include '.\functions.ahk'          ✅
#Include '.\roa.ahk'                ✅
#include '.\init.ahk'               ✅
#Include ".\bookmarks.ahk"          ✅
#Include ".\menus.ahk"              ✅
#Include ".\code.ahk"               ✅
#Include ".\hotstrings.ahk"         ✅
#Include ".\system.ahk"             ✅
#Include ".\chrome.ahk"             ✅
#Include ".\hotkeys-global.ahk"     ✅
#Include ".\menu.ahk"               ✅
#Include ".\menu-webview.ahk"       ✅
```

---

## ⚠️ Notas Importantes

### Before Limpieza:
1. **Hacer commit del estado actual** ✅ (por hacer)
2. **Hacer backup de carpetas grandes** (skills, commands, .skills)
3. **Verificar que no hay trabajo en progreso** en esos directorios

### Contenido de skills/ (ejemplo):
- `azure-devops-cli/`
- `branch-namer/`
- `claude-usage/`
- `commit-changes/`
- Y muchos más... (~40+ subdirectorios)

### ¿Por qué no se usan?
Según el README.md original, se mencionaba un "Sistema de Skills Extensible", pero:
- No hay ningún `#Include` que los cargue
- No hay código que los importe dinámicamente
- No hay referencias en ningún archivo .ahk

### Posible explicación:
- Fueron planeados como feature pero nunca implementados
- O fueron reemplazados por otro sistema
- O son de un proyecto diferente que se copió aquí

---

## 🎯 Recomendación Final

### Eliminar con confianza:
- ✅ `bookmarks-missing.txt`
- ✅ `missing-paths.log`  
- ✅ `log.txt`
- ✅ `menu-webview-example.ahk`
- ✅ `skills/` (después de backup)
- ✅ `commands/` (después de backup)
- ✅ `.skills/` (después de backup)
- ✅ `Archived/` (después de backup)

### Evaluar antes de eliminar:
- ⚠️ `cleanup-config.ps1` - ¿Lo usas manualmente?
- ⚠️ `wrench.png` - ¿Usado en algún ImageSearch?

### Mantener:
- ✅ Todo lo demás que esté en el root
- ✅ Toda la carpeta `lib/`
- ✅ Toda la carpeta `ui/`

---

## 💾 Impacto Estimado

Después de limpieza:
- **Archivos eliminados**: ~50-60 archivos
- **Espacio liberado**: ~2-5 MB (dependiendo del contenido de skills)
- **Complejidad reducida**: Estructura más clara y mantenible
- **Build más rápido**: build.bat no copiará carpetas innecesarias

---

## 📋 Checklist de Limpieza

- [ ] Commit estado actual (en progreso)
- [ ] Backup de skills/ commands/ .skills/ Archived/
- [ ] Ejecutar Fase 1 (logs temporales)
- [ ] Ejecutar Fase 2 (ejemplos)
- [ ] Revisar imágenes (Fase 3)
- [ ] Ejecutar Fase 4 (directorios grandes)
- [ ] Evaluar Fase 5 (scripts utilidad)
- [ ] Actualizar build.bat (remover copias de carpetas eliminadas)
- [ ] Actualizar README.md (remover referencias a skills/commands)
- [ ] Commit limpieza
- [ ] Verificar que el script sigue funcionando
