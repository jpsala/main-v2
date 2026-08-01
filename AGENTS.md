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

## Web, Internet E Instalaciones

- Usar web/internet libremente por defecto cuando conocimiento externo o cambiante evite adivinar: docs oficiales, releases, issues/source, metadata de paquetes, errores, APIs y comparativas. No enviar secretos, `.env`, codigo privado sensible, datos personales ni credenciales a servicios externos.
- Si evidencia online contradice el repo local, docs del proyecto o comportamiento observado, consultar a JP antes de decidir; presentar ambas evidencias, fuentes e impacto practico.
- Antes de instalar dependencias, CLIs globales, paquetes de sistema, herramientas de package-manager o binarios/scripts remotos, pedir autorizacion explicita con comando exacto, alcance, motivo, riesgos, alternativa, cambios esperados y rollback. Tratar `curl | sh`/scripts remotos como alto riesgo y preferir alternativas auditables.

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

## Agentic OS Local

- `/flow` es la única entrada Pi cotidiana: Pensar, Planear, Hacer o Cerrar.
- Planear usa `balanced` con Sol Medium como ruta normal, incluso para trabajo multifile/cross-layer/nativo acotado. `strong` con Sol High queda sólo para ambigüedad material, arquitectura abierta, seguridad/auth/privacidad, irreversibilidad, alto impacto productivo o fallos materiales difíciles de detectar. `economical` con Luna requiere pedido explícito de JP por cuota y checks deterministas. Hacer abre una sesión nueva enlazada y bloquea sin fallback si falta modelo o auth.
- `Ctrl+P` alterna Sol Medium/High; `Ctrl+L` conserva la selección manual de modelo.
- Hacer ejecuta directamente allí sin Agent ni auto-send; Cerrar guarda sólo valor durable faltante. No recrear slash lifecycle locales ni motores retirados.
- `aos-realinear-os` abre `docs/topics/agentic-os-operations.md`; init/adopt/update/align/perfect son operaciones manager de `C:/dev/os`.
- `docs/skills/` retiene sólo skills propias de main y `.agents/skills` sigue siendo su junction de compatibilidad.
- `advisor` se usa para decisiones fuertes, arquitectura, seguridad o evidencia en conflicto; no como ceremonia.

## Validacion recomendada

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
git diff --check
```

Para cambios de runtime AHK, seguir el protocolo anterior y agregar una verificacion especifica del modulo afectado; evitar arrancar la automatizacion completa sin permiso.
