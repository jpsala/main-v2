# Desarrollo

## Setup basico

```powershell
copy config.ini.dist config.ini
copy .env.example .env   # opcional, solo si usas hotstrings/API keys locales
main.ahk
```

Requisitos: Windows 10/11, AutoHotkey v2 y WebView2 Runtime.

## Configuracion local

- `config.ini` es estado real de maquina y esta ignorado por git.
- `config.ini.dist` es el esquema portable que debe mantenerse actualizado.
- `.env` es local/secreto y no se versiona.
- Logs y snapshots (`*.log`, `settings-debug.txt`, `gesture-rules-debug.txt`, etc.) son runtime/locales.

## Flujo para agentes

1. Identificar si el pedido toca config, menus, ROA, bookmarks, editor/chords, gestos o UI.
2. Leer `docs/.generated/context-index.md`, `docs/WORKING_MEMORY.md` y el topic relevante.
3. Leer solo los modulos necesarios.
4. Cambiar en lote chico y preservar memoria muscular.
5. Actualizar docs si cambia una convencion o ruta de trabajo.
6. Validar con comandos seguros.

## Hot reload

`init.ahk` revisa `filesToCheckForReload` cada 5 segundos cuando no esta compilado. Si agregas un modulo o HTML que deba recargar en desarrollo, sumarlo a esa lista.

## Validacion

Contexto agentico:

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
git diff --check
```

Runtime AHK:

- No arrancar/reiniciar la automatizacion completa sin permiso.
- Evitar `AutoHotkey64.exe /ErrorStdOut main.ahk` automaticamente porque puede quedar residente.
- Para cambios complejos, crear probe aislado o pedir permiso para una prueba manual.

## Build

Superficies existentes:

- `build.bat`
- `installer.iss`
- `BUILD-INSTALLER-ANALISIS.md`

Antes de tocar build/installer, leer esos archivos y verificar outputs ignorados (`dist/`, `.exe`, `.zip`).
