# Proyecto

`main-v2` es un command center personal para Windows construido con AutoHotkey v2 y WebView2.

## Proposito

Convertir Windows en un espacio keyboard-first con:

- lanzamiento y reutilizacion de ventanas via Run-or-Activate;
- menus jerarquicos para apps, navegadores, proyectos y herramientas;
- bookmarks persistentes de ventanas;
- perfiles de Vivaldi/Chrome centralizados por config;
- automatizacion de VS Code/Cursor;
- gestos de mouse contextuales;
- UIs WebView2 locales para settings, menus, hints y calendarios.

## No objetivos

- No ser una app consumer zero-config.
- No ser cross-platform.
- No transformar workflows personales en abstracciones genericas sin necesidad.
- No almacenar secretos ni estado local sensible en git.

## Stack

- AutoHotkey v2.
- WebView2 para ventanas HTML locales.
- PowerShell/Bat/Inno Setup para build/instalador.
- Scripts de contexto con Bun/TypeScript sólo para índice y audit de contexto agentic.

## Superficies importantes

| Superficie | Archivos |
| --- | --- |
| Entrada/runtime | `main.ahk`, `init.ahk` |
| Menus | `menus.ahk`, `menu-actions.ahk`, `menu-webview.ahk`, `ui/menu.html` |
| Reuso de ventanas | `roa.ahk` |
| Bookmarks | `bookmarks.ahk`, `config.ini` |
| Chords | `menus-whichkey.ahk`, `lib/chord-hotkeys.ahk`, `ui/chord-hint.html` |
| Editor | `code.ahk`, `menus-whichkey.ahk`, `lib/chord-hotkeys.ahk` |
| Gestos | `mouse-gestures*.ahk`, `docs/features/gestures.md` |
| Settings/WebView | `settings-window.ahk`, `ui/settings.html`, `ui/shared.css`, `ui/ahk-bridge.js` |
| Portable | `MainPortable/` |

## Frontera agentic local

Este repo conserva la capa AOS durable: docs, índices, Working Memory, topics,
tracks, specs, skills y gates locales. El harness OMP activo gobierna la
ejecución agentic y sus decisiones runtime; Main no las prescribe ni valida.
El launcher Pi AHK es una integración de producto externa y queda fuera de esa
capa.
