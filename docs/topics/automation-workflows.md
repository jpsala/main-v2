---
id: automation-workflows
status: active
kind: guide
triggers:
  - menus
  - roa
  - run or activate
  - bookmarks
  - perfiles
  - vivaldi
  - cursor
  - vscode
  - gestos
  - which-key
primary_refs:
  - menus.ahk
  - menu-actions.ahk
  - roa.ahk
  - bookmarks.ahk
  - code.ahk
  - menus-whichkey.ahk
  - wezterm-command-palette.ahk
  - lib/chord-hotkeys.ahk
  - docs/features/gestures.md
---

# Automation Workflows

## Menús

`Win+A`, `Win+W` y `Win+C` reutilizan las definiciones de `menus.ahk`, pero las presentan mediante la Command Palette compartida. Con consulta vacía muestran grupos y hasta diez aceleradores (`1`–`9`, `0`); al escribir buscan globalmente todas las acciones de su propio menú.

Patrón habitual:

1. Agregar el item visible en `options.items`.
2. Preferir una `action` declarativa.
3. Mover comportamiento reusable a `menu-actions.ahk` si supera una línea.
4. Preferir `Roa(...)` cuando se quiere reusar/minimizar una ventana existente.
5. Validar el catálogo aislado con `tests/command-palette-probe.ahk`.

## ROA

`roa.ahk` concentra launch/reuse. Antes de hardcodear busquedas de ventanas, revisar alias/config existente.

## Browser profiles

Los launchers se arman desde `init.ahk`, `config.ini` y `config.ini.dist`. No duplicar command strings si ya existe `vivaldiWithMainProfile`, `vivaldiWithAIProfile`, `chromeWithWorkProfile`, etc.

## Bookmarks

`bookmarks.ahk` usa `config.ini` para persistencia. No modificar bookmarks reales salvo que JP pida trabajar sobre estado actual.

## Which-Key / chords legado

- Motor conservado: `lib/chord-hotkeys.ahk`.
- Adapter compartido y toggle: `menus-whichkey.ahk`.
- UI conservada: `ui/chord-hint.html`.

Para volver temporalmente al renderer anterior de A/W/C, alternar exclusivamente las dos líneas documentadas como `Main menu renderer toggle` en `main.ahk`.

### WezTerm Command Palette

Implementado: `wezterm-command-palette.ahk` carga con `JsonLoad` el catálogo neutral `C:/dev/wezterm/config/command-menu.json`, materializa grupos y acciones y registra `Ctrl+Shift+P` bajo un `HotIf` limitado a `wezterm-gui.exe`. La raíz muestra los submenús; dentro o fuera de ellos, cualquier consulta busca globalmente todas las acciones. Al abrir captura la ventana origen por HWND/PID; antes de cada fase exige que siga viva y enfocada. El bridge file v2 es single-writer y completa `claim` -> `verify` -> `commit` con `nonce`, fingerprint, path y expiración estrictos; WezTerm resuelve la ruta y conserva la ejecución en acciones Lua. `Ctrl+Alt+Shift+P` mantiene la command palette nativa. El probe focal es `tests/wezterm-command-palette-probe.ahk`.

La decisión, invariantes, clean cutover y verificación autoritativos viven en `C:/dev/wezterm/docs/tracks/themes-and-palette.md`; no duplicarlos aquí.

## Editor / palettes

- Automatización Code/Cursor: `code.ahk`.
- Los siete árboles editor-only usan `MenuCommandPaletteRegisterWithActions(...)`.
- `Alt+G/B/T/F/Z/S` conserva sus launchers amigables; `Ctrl+Alt+C` conserva References.
- El bloque Which-Key anterior permanece comentado junto al bloque activo en `InitVSCodeControllerChords()`; activar sólo uno de los dos.
- El modo Vim global fue retirado del runtime principal; no incluir `vim-mode.ahk` ni `vim-keymap*.ahk` salvo pedido explícito de restaurarlo.

## Gestos

Lectura: `docs/features/gestures.md` -> `mouse-gestures-conditions.ahk` -> `mouse-gestures-wizard.ahk` -> `mouse-gestures.ahk`.

Editar condiciones para comportamiento normal; motor solo para reconocimiento/matching/dispatch.
