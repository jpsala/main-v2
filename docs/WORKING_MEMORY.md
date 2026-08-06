# Working Memory

Estado vivo corto del repo. Mantener liviano.

Ultima actualizacion: 2026-08-04.

## Foco Único De Ejecución

- **Estado:** `needs_planning`.
- **Siguiente acción:** elegir un único brief para runtime AHK o command palette; preservar WIP y no arrancar la automatización completa.

## Lectura rapida

| Area | Estado | Abrir primero | Siguiente accion |
| --- | --- | --- | --- |
| Runtime AHK | active | `docs/topics/project-architecture.md` | Preservar include order, hot reload y config local. |
| Menus/ROA/bookmarks | active | `docs/topics/automation-workflows.md` | Cambios chicos en `menus.ahk`, `menu-actions.ahk`, `roa.ahk`, `bookmarks.ahk`. |
| Gestos | active | `docs/features/gestures.md` | Editar condiciones antes que motor salvo cambio de reconocimiento. |
| Capa agentic | active | `docs/topics/portable-multiharness-contract.md`, `docs/topics/agentic-os-operations.md` | Traycer/harness nativo para interacción cotidiana; OMP standalone/manual; mantener docs/context index/audit y discovery sin runtime local. |
| Docs/contexto | active | `docs/topics/docs-knowledge-system.md` | Promover conocimiento durable a topics/docs, no transcript. |
| Launcher Pi | active product integration | `menu-actions.ahk`, `menus.ahk` | Preservar presets, etiquetas, tests y `C:\tools\pi-menu.ps1`; no confundirlo con el harness agentic. |

## Decisiones recientes

- 2026-06-30: `main-v2` fue agregado al registry AOS upstream y adoptado como downstream local.
- 2026-06-30: `AGENTS.md` se compacto; la version larga previa quedo en `docs/reference/agent-guide-before-aos-2026-06-30.md`.
- 2026-06-30: se agregaron scripts de contexto, topics, tracks, skills AOS y adapter Pi local.
- 2026-07-09: AOS local alineado con routing actual: `advisor` solo para decisiones fuertes/loops largos, fleet updates desde `C:/dev/os` con `pi_long_task`, y `.agents/skills` como junction estable.
- 2026-07-11: Los registros directos de los menús `Win+A/W/C` quedaron comentados durante la evaluación de la command palette; sus definiciones y acciones siguen disponibles para el catálogo.
- 2026-07-11: `Win+E` (`#e`) abre una command palette estilo PowerToys con acciones de los menús A/W/C, fuzzy search, metadata y dispatch por closures; `Win+A/W/C` volvieron a los menús convencionales which-key. `CommandPaletteInit(levelsPerPage := 0, groupsFirst := false)` conserva la lista plana; valores `1+` aplanan esa cantidad de niveles por página y habilitan drill-down y back. `groupsFirst=false` ordena acciones antes que submenús y `true` los invierte. La búsqueda respeta la página visible: para buscar más profundo hay que abrir el submenú. CopyQ y favoritos quedan fuera de V1. Los probes AHK pasan por `scripts/run-ahk-probe.ps1`, que captura runtime errors sin diálogos, espera el proceso, aplica timeout y valida el exit code real.
- 2026-07-11: La command palette usa IDs estructurales estables y frecency exponencial local con vida media de 14 días. Al ejecutar una acción se actualizan también sus grupos padres; sin consulta ordena por frecency y con consulta solo desempata el fuzzy. El estado vive fuera del repo en `%LOCALAPPDATA%\main-v2\command-palette-frecency.json`.
- 2026-08-04: la capa agentic migró a Traycer/harness nativo sin runtime, manifest ni adapter local; OMP queda standalone/manual y el launcher Pi AHK continúa como integración de producto independiente.

## Riesgos

- `config.ini` y `.env` son locales/privados; no versionar ni usar como fuente portable salvo para entender valores actuales cuando JP lo pide.
- Preservar todo WIP AHK y de configuración/logs; esta migración no toca el runtime de escritorio, `menu-actions.ahk`, `menus.ahk` ni sus probes.
- Hay notas/logs grandes y archivos de analisis historicos; no borrar sin revisar si aun aportan contexto.
- Evitar correr `main.ahk` completo como test automatico: es automatizacion viva del escritorio.

## Pendientes detectados

1. Revisar si `docs/constelaciones-smoke-2026-06-18.md` debe quedarse en este repo, moverse a referencia externa o archivarse.
2. Decidir si los analisis raiz (`ANALISIS-PROYECTO.md`, `ARCHIVOS-PARA-LIMPIAR.md`, `PORTABILIDAD-PATHS.md`, etc.) deben migrar progresivamente a `docs/reference/`.
3. Evaluar la command palette en `Win+A` antes de restaurar o reasignar los menús directos A/W/C.

## Comandos utiles

```powershell
bun run context:index
bun run context:audit
bun run context:refresh
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-probe.ahk
```
