# Working Memory

Estado vivo corto del repo. Mantener liviano.

Ultima actualizacion: 2026-06-30.

## Lectura rapida

| Area | Estado | Abrir primero | Siguiente accion |
| --- | --- | --- | --- |
| Runtime AHK | active | `docs/topics/project-architecture.md` | Preservar include order, hot reload y config local. |
| Menus/ROA/bookmarks | active | `docs/topics/automation-workflows.md` | Cambios chicos en `menus.ahk`, `menu-actions.ahk`, `roa.ahk`, `bookmarks.ahk`. |
| Gestos | active | `docs/features/gestures.md` | Editar condiciones antes que motor salvo cambio de reconocimiento. |
| OS local | active | `docs/topics/agentic-os-operations.md` | AOS adoptado localmente; mantener docs/context index/audit/skills. |
| Docs/contexto | active | `docs/topics/docs-knowledge-system.md` | Promover conocimiento durable a topics/docs, no transcript. |
| Pi adapter | active | `docs/topics/pi-agentic-os.md` | `.pi` con comandos AOS locales instalado. |

## Decisiones recientes

- 2026-06-30: `main-v2` fue agregado al registry AOS upstream y adoptado como downstream local.
- 2026-06-30: `AGENTS.md` se compacto; la version larga previa quedo en `docs/reference/agent-guide-before-aos-2026-06-30.md`.
- 2026-06-30: se agregaron scripts de contexto, topics, tracks, skills AOS y adapter Pi local.

## Riesgos

- `config.ini` y `.env` son locales/privados; no versionar ni usar como fuente portable salvo para entender valores actuales cuando JP lo pide.
- Hay cambios preexistentes en runtime (`lib/utils.ahk`, `menu-actions.ahk`, `menus.ahk`) y logs; no revertirlos.
- Hay notas/logs grandes y archivos de analisis historicos; no borrar sin revisar si aun aportan contexto.
- Evitar correr `main.ahk` completo como test automatico: es automatizacion viva del escritorio.

## Pendientes detectados

1. Revisar si `docs/constelaciones-smoke-2026-06-18.md` debe quedarse en este repo, moverse a referencia externa o archivarse.
2. Decidir si los analisis raiz (`ANALISIS-PROYECTO.md`, `ARCHIVOS-PARA-LIMPIAR.md`, `PORTABILIDAD-PATHS.md`, etc.) deben migrar progresivamente a `docs/reference/`.
3. Agregar tests/probes AHK por modulo cuando aparezca una tarea de runtime concreta.

## Comandos utiles

```powershell
bun run context:index
bun run context:audit
bun run context:refresh
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
```
