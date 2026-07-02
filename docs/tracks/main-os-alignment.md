---
status: active
updated: 2026-06-30
priority: medium
---

# Main OS Alignment

## Estado

AOS local adoptado: AGENTS compacto, docs core, topics, skills, scripts de contexto y adapter Pi.

## Hecho

- Preservada la guia larga previa en `docs/reference/agent-guide-before-aos-2026-06-30.md`.
- Instalados scripts `context-index`, `context-refresh`, `agent-context-audit` y skills toggle.
- Instalados prompts/extensiones Pi `/aos-*`.
- Agregados topics locales para arquitectura, workflows y operaciones AOS.
- Worker de alineacion 2026-06-30: prompts/skills Pi quedaron adaptados a repo downstream; `aos-align-os-project` ahora reporta nota de registry sin editar registry manager-only, e init/adopt redirigen al upstream manager.

## Next Step

Revisar en un lote separado los documentos historicos de raiz y decidir si migrarlos a `docs/reference/` o dejarlos como artefactos raiz.

## Referencias

- `AGENTS.md`
- `docs/WORKING_MEMORY.md`
- `docs/TOPICS.md`
- `docs/OPEN_QUESTIONS.md`
