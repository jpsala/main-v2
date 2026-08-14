# AGENTS.md

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

- Core: `main.ahk`; startup/config/hot reload: `init.ahk`; Run-or-Activate: `roa.ahk`.
- Menús `Win+A/W/C`: `menus.ahk`, `menu-actions.ahk`; chords: `menus-whichkey.ahk`, `lib/chord-hotkeys.ahk`.
- Bookmarks y editores: `bookmarks.ahk`, `config.ini`, `code.ahk`.
- Gestos: `docs/features/gestures.md` y `mouse-gestures*.ahk`.
- WebView: `settings-window.ahk`, `menu-webview.ahk`, `ui/*.html`.
- Toolkit separado: `MainPortable/` y `MainPortable/AGENTS.md`.

## Web, Internet E Instalaciones

- Si una tarea consulta internet, no enviar secretos, `.env`, código privado, datos personales ni credenciales.
- Login nuevo, cuentas/datos privados y efectos externos sensibles conservan los gates locales.
- Si evidencia online contradice repo, docs o runtime, consultar a JP con fuentes e impacto.
- Antes de instalar paquetes, CLIs o scripts/binarios remotos, pedir autorización con comando, alcance, riesgos, alternativa y rollback; evitar `curl | sh`.

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
- Los identificadores no distinguen mayusculas: no nombrar una variable como una funcion nativa (`coordMode := CoordMode(...)` rompe la llamada).
- `JsonDump` serializa `Map` y `Array`, no object literals; mantener closures fuera del payload JSON.
- Pasar funciones como objetos (`Func("Name")`, closures o `.Bind(...)`), no como identificadores ambiguos.
- No dejar hotkeys/timers/hooks temporales activos despues de un flujo modal.
- No ejecutar `AutoHotkey64.exe /ErrorStdOut main.ahk` automaticamente: puede quedar residente. Preferir probe aislado o pedir permiso.

## Protocolo de validacion AutoHotkey

- Para cualquier cambio AHK, leer y seguir `docs/topics/autohotkey-validation.md`.
- Ejecutar probes solo con `scripts/run-ahk-probe.ps1`; nunca usar `main.ahk` como test ni confiar en el exit code directo del exe GUI.
- Validar por capas: carga -> logica/JSON -> WebView/JS -> hot reload -> proceso/log -> smoke fisico. No reiniciar `main.ahk`.

## Frontera AOS/OMP

<!-- aos-bootstrap: stable-bootstrap-v1 -->
<!-- aos-runtime-authority: omp -->
<!-- aos-local-authority: product, domain, data, security, external-effects -->

- Bootstrap estable: OMP gobierna exclusivamente la ejecución de agentes y su runtime; Main conserva la autoridad sobre producto, dominio, datos, seguridad y gates de efectos externos. El runtime de producto de Pi Launcher en AHK/WebView2 sigue siendo comportamiento de producto, no gobernanza agentic.

- La capa AOS local conserva conocimiento durable, continuidad, docs, índices, Working Memory, topics, tracks, specs, skills y gates propios de Main.
- El harness OMP activo gobierna modelos, effort, tools, browser, todos, agentes, planificación, paralelización, idioma, estilo y modos runtime. Este repo no prescribe ni valida esas decisiones.
- No añadir como default cotidiano un runtime, manifest, package, prompts lifecycle o adapter agentic que duplique el harness. Conservar skills, extensiones, wrappers y scripts locales opt-in que aporten una capacidad real.
- `docs/skills/` contiene capacidades locales reales y `.agents/skills` mantiene discovery estable.
- El launcher Pi de `menu-actions.ahk`/`menus.ahk` es producto de escritorio externo (`C:\tools\pi-menu.ps1`), no la capa agentic del repo. Preservar sus presets, etiquetas y probes salvo pedido explícito.

## Validacion recomendada

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
git diff --check
```

Para cambios de runtime AHK, seguir el protocolo anterior y agregar una verificacion especifica del modulo afectado; evitar arrancar la automatizacion completa sin permiso.
