# AGENTS.md

Guia corta para agentes en este repo.

## Mision

`main-v2` es una capa personal de automatizacion Windows con AutoHotkey v2 + WebView2. Sirve para lanzar/reusar ventanas, perfiles de navegador, menus keyboard-first, bookmarks, flujos de VS Code/Cursor, gestos de mouse y pequenas UIs locales.

No es una libreria generica ni una app consumer. Preservar memoria muscular y configuracion local salvo pedido explicito de redisenar.

## Lectura inicial liviana

1. `docs/.generated/context-index.md` si existe.
2. `docs/WORKING_MEMORY.md`.
3. `docs/TOPICS.md` para elegir topic.
4. Topic o archivo puntual segun el pedido.
5. Para cambios AHK no triviales: `main.ahk` + el modulo afectado.

Referencia profunda preservada del AGENTS anterior: `docs/reference/agent-guide-before-aos-2026-06-30.md`.

## Mapa rapido

- Entrada/include graph: `main.ahk`.
- Startup, config, perfiles, hot reload: `init.ahk`.
- Menus principales `Win+A`, `Win+W`, `Win+C`: `menus.ahk` y `menu-actions.ahk`.
- Run-or-Activate: `roa.ahk`.
- Which-key/chords: `menus-whichkey.ahk`, `lib/chord-hotkeys.ahk`, `ui/chord-hint.html`.
- Bookmarks: `bookmarks.ahk`, `config.ini`.
- VS Code/Cursor: `code.ahk`.
- Gestos: `docs/features/gestures.md`, `mouse-gestures-conditions.ahk`, `mouse-gestures-wizard.ahk`, `mouse-gestures.ahk`.
- WebView UIs: `settings-window.ahk`, `menu-webview.ahk`, `ui/*.html`.
- Portable toolkit separado: `MainPortable/` y `MainPortable/AGENTS.md`.

## Reglas de cambio

- No tocar `.env`, `config.ini`, logs ni datos locales salvo pedido explicito.
- No commitear secretos ni rutas privadas nuevas; reflejar esquemas en `.env.example` o `config.ini.dist`.
- No reiniciar manualmente `main.ahk` salvo pedido: `init.ahk` ya tiene hot reload en desarrollo.
- Si agregas modulo AHK editable, incluirlo en `main.ahk` y en `filesToCheckForReload` de `init.ahk`.
- Si agregas HTML/WebView editable, ponerlo en `ui/` y sumarlo a hot reload si aplica.
- Preferir `Roa(...)` para lanzar/reusar/minimizar ventanas.
- Mantener menus declarativos y acciones sincronizadas: item visible + `switch key` o action correspondiente.
- Para UIs WebView usar `ui/shared.css` y `ui/ahk-bridge.js`.
- Para gestos, editar condiciones antes que motor; usar docs/features/gestures.md como guia.
- Para cambios grandes, crear/actualizar spec o track antes de tocar varias superficies.

## AutoHotkey v2 gotchas

- El orden de `#Include` es orden de ejecucion; top-level code corre al cargar.
- Evitar llamadas top-level nuevas salvo que el orden este verificado.
- Pasar funciones como objetos (`Func("Name")`, closures o `.Bind(...)`), no como identificadores ambiguos.
- No dejar hotkeys/timers/hooks temporales activos despues de un flujo modal.
- No ejecutar `AutoHotkey64.exe /ErrorStdOut main.ahk` automaticamente: puede quedar residente. Preferir probe aislado o pedir permiso.

## Agentic OS local

- Comandos AOS locales viven en `docs/skills/` y `.pi/`.
- `aos-realinear-os`: abrir `docs/topics/agentic-os-operations.md` y auditar solo capa agentica por defecto.
- `aos-guardar-sesion` / `aos-checkpoint`: persistir valor durable en docs sin transcript.
- `aos-cerrar-sesion`: guardar valor durable y cerrar con sintesis final.
- `aos-continuar-sesion`: alias legado de nueva sesion; no significa seguir en el hilo actual.
- `aos-sigamos` / `aos-gol-lite`: avanzar en lote chico verificable.
- `aos-orquestar` / `aos-fanout`: usar subagentes solo si JP lo pide o si aporta paralelismo claro.

## Validacion recomendada

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
git diff --check
```

Para cambios de runtime AHK, agregar una verificacion especifica del modulo afectado y evitar arrancar la automatizacion completa sin permiso.
