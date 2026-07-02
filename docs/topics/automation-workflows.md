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
  - lib/chord-hotkeys.ahk
  - docs/features/gestures.md
---

# Automation Workflows

## Menus

Para `Win+A`, `Win+W`, `Win+C` mirar `menus.ahk`.

Patron habitual:

1. Agregar item visible en `options.items`.
2. Agregar accion en `switch key` o usar `action` declarativa.
3. Mover comportamiento reusable a `menu-actions.ahk` si supera una linea.
4. Preferir `Roa(...)` cuando se quiere reusar/minimizar ventana existente.

## ROA

`roa.ahk` concentra launch/reuse. Antes de hardcodear busquedas de ventanas, revisar alias/config existente.

## Browser profiles

Los launchers se arman desde `init.ahk`, `config.ini` y `config.ini.dist`. No duplicar command strings si ya existe `vivaldiWithMainProfile`, `vivaldiWithAIProfile`, `chromeWithWorkProfile`, etc.

## Bookmarks

`bookmarks.ahk` usa `config.ini` para persistencia. No modificar bookmarks reales salvo que JP pida trabajar sobre estado actual.

## Which-key / chords

- Motor: `lib/chord-hotkeys.ahk`.
- Bridge de menus: `menus-whichkey.ahk`.
- UI: `ui/chord-hint.html`.

Preferir keys de mano izquierda cuando se agregan shortcuts para flujos mouse+keyboard.

## Editor / chords

- Automatizacion Code/Cursor: `code.ahk`.
- Chords/which-key: `menus-whichkey.ahk`, `lib/chord-hotkeys.ahk`, `ui/chord-hint.html`.
- El modo Vim global fue retirado del runtime principal; no incluir `vim-mode.ahk` ni `vim-keymap*.ahk` salvo pedido explicito de restaurarlo.

Preferir chords editor-only antes que reintroducir una capa modal global.

## Gestos

Lectura: `docs/features/gestures.md` -> `mouse-gestures-conditions.ahk` -> `mouse-gestures-wizard.ahk` -> `mouse-gestures.ahk`.

Editar condiciones para comportamiento normal; motor solo para reconocimiento/matching/dispatch.
