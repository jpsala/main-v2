---
id: agentic-os-operations
status: active
kind: how-to
triggers:
  - traycer
  - omp standalone
  - agentic os
  - realinear os
  - auditar sistema agentico
  - reparar sistema agentico
  - actualizar os
  - contexto agentico
primary_refs:
  - AGENTS.md
  - docs/WORKING_MEMORY.md
  - docs/TOPICS.md
  - docs/topics/portable-multiharness-contract.md
  - docs/.generated/context-index.md
  - docs/skills/
  - scripts/context-index.ts
  - scripts/agent-context-audit.ts
---

# Operaciones Agentic Traycer

## Alcance

Este repo es un downstream sobre Traycer y un harness nativo: mantiene contexto local, docs,
skills e índice/audit, sin copiar un runtime, manifest, package, prompts
lifecycle ni gobierno manager externo.

Por defecto, realinear la capa agentic no cambia runtime AHK, configuración real,
datos, shortcuts ni automatización viva. El launcher Pi AHK es producto externo
y queda fuera de la limpieza agentic.
- OMP queda standalone/manual; preservar la integración Pi y sus gates locales.

## Lectura mínima

1. `AGENTS.md`
2. `docs/.generated/context-index.md`
3. `docs/WORKING_MEMORY.md`
4. `docs/TOPICS.md`
5. Topic o track puntual

## Revisar

- Ruta caliente corta y actual.
- Topics con frontmatter, triggers y refs existentes.
- Tracks activas con status, updated y próximo paso.
- `docs/skills/` como canon local.
- `.agents/skills` como discovery OMP estable.
- Routing en `docs/topics/agent-tool-routing.md` y `docs/reference/tool-routing.yaml`.
- Scripts `context-index.ts`, `agent-context-audit.ts` y `context-refresh.ts`.
- Ausencia de runtime, manifests, packages o adapters agentic locales.
- Preservación explícita del launcher Pi en `menu-actions.ahk`, `menus.ahk` y su probe.

## Corregir sin preguntar

- Links rotos obvios.
- Índice generado stale.
- Frontmatter o triggers faltantes.
- Compactar ruta caliente sin perder contenido.
- Actualizar `WORKING_MEMORY.md` con estado vivo real.

## Preguntar antes

- Borrar memoria o documentos históricos.
- Mover archivos raíz si su destino no es claro.
- Tocar `config.ini`, `.env`, logs privados o runtime AHK.
- Cambiar presets, etiquetas o contrato del launcher Pi externo.
- Reiniciar o ejecutar automatización viva.

## Cierre

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
```

Reportar aplicado, omitido, pendientes y evidencia.
