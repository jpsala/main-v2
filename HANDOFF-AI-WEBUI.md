# Handoff - AI WebUI migration (main <- ai-assistant)

Fecha: 2026-02-21
Proyecto destino: `/mnt/c/dev/main`
Proyecto fuente: `/home/jp/dev/ai-assistant`

## Objetivo
Tener en `main` la experiencia completa del proyecto fuente:
- Main window WebUI
- Prompt picker WebUI
- Settings WebUI (provider/model/api keys/hotkeys)
- Prompt editor WebUI (incluyendo hotkeys por prompt, single y chord)

## Estado actual (hecho)
1. Se agrego un modulo nuevo: `ai-webui.ahk`
   - Main window WebUI
   - Settings WebUI
   - Prompt editor WebUI
   - Hotkeys dinamicas por config (`hotkey_mainWindow`, `hotkey_promptPicker`, etc)
   - Registro de hotkeys de prompts con soporte de chords (`Alt+T -> C`)
   - Fetch de modelos por provider para Settings/Editor

2. Se agrego/modifico picker separado: `ai-picker.ahk`
   - El picker sigue separado
   - La hotkey del picker se deja para manejar desde Settings WebUI

3. Se agrego soporte de chords: `lib/chord-hotkeys.ahk`

4. Integracion en entrypoint:
   - `main.ahk` incluye:
     - `#Include ".\\ai.ahk"`
     - `#Include ".\\ai-picker.ahk"`
     - `#Include ".\\ai-webui.ahk"`

5. Integracion en reload watcher:
   - `init.ahk` observa:
     - `./ai-picker.ahk`
     - `./ai-webui.ahk`
     - `./lib/chord-hotkeys.ahk`

6. `ai.ahk` sincroniza con WebUI:
   - Al cargar prompts registra hotkeys de prompts
   - Al recargar prompts actualiza picker + WebUI

7. Se copiaron UI files del proyecto fuente al destino:
   - `ui/index.html`
   - `ui/settings.html`
   - `ui/prompt-editor.html`
   - `ui/picker.html`

8. Hotkey de Main window cambiada a `Alt+``
   - Default en codigo: `!vkC0`
   - Persistido en `config.ini` dentro de `[ai]`:
     - `hotkey_mainWindow=!vkC0`

## Lo importante para probar rapido
1. Recargar `main.ahk`.
2. Probar Main window con `Alt+``.
3. En Main window abrir `Settings` y verificar:
   - Provider
   - Model
   - API keys
   - Hotkeys
4. Probar `Ctrl+Q` para Prompt picker (si esta asignado en Settings).
5. Abrir Prompt Editor y probar:
   - crear/editar/borrar prompt
   - hotkey simple
   - hotkey chord (ejemplo `Alt+T -> C`)

## Soporte de chord hotkeys (estado)
Ya esta soportado por parser y runtime.
Formas validas para prompt hotkey:
- `!t,c`
- `Alt+T -> C`

Nota: en este repo `!t` ya esta usado por otros scripts (`discord.ahk`, `tv.ahk`).
Si queres usar `Alt+T` como prefijo para prompts, hay que liberar/remapear esos `!t` existentes.

## Riesgos / pendientes
1. No se ejecuto runtime end-to-end desde este entorno (no se corrio AutoHotkey aqui).
2. El worktree esta MUY sucio con cambios no relacionados (incluye muchos archivos en `Archived/` y renombres).
   - Antes de commit/PR, separar cambios AI de cambios no relacionados.
3. `config.ini` esta en UTF-16LE. Cualquier script externo que lo edite tiene que respetar encoding.

## Archivos clave tocados para esta migracion
- `ai-webui.ahk` (nuevo)
- `ai-picker.ahk` (nuevo/modificado)
- `lib/chord-hotkeys.ahk` (nuevo)
- `ai.ahk`
- `main.ahk`
- `init.ahk`
- `ui/index.html`
- `ui/settings.html`
- `ui/prompt-editor.html`
- `ui/picker.html`
- `config.ini` (`[ai].hotkey_mainWindow`)

## Prompt sugerido para nueva sesion
Usa este texto al iniciar una sesion nueva:

"Continuemos desde `/mnt/c/dev/main/HANDOFF-AI-WEBUI.md`.
Quiero validar y cerrar la migracion WebUI de AI en `main`.
Primero revisa estado real de hotkeys/conflictos y hace una prueba guiada de Main window, Settings, Prompt Editor y Picker.
Despues proponeme los cambios minimos para dejar listo `Alt+T -> C` sin conflictos." 

