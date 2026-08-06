---
status: historical
updated: 2026-08-04
priority: medium
---

# Main OS Alignment

## Estado

Registro histórico de la adopción AOS del 2026-06-30, supersedida el 2026-08-04
por la capa OMP nativa y, para la autoridad diaria, posteriormente supersedida
el 2026-08-06 por Traycer con harness nativo. Los prompts/extensiones
mencionados abajo ya no son superficies activas del repo.

## Hecho en 2026-06-30

- Preservada la guia larga previa en `docs/reference/agent-guide-before-aos-2026-06-30.md`.
- Instalados scripts `context-index`, `context-refresh`, `agent-context-audit` y skills toggle.
- Instalados prompts/extensiones Pi `/aos-*`.
- Agregados topics locales para arquitectura, workflows y operaciones AOS.
- Worker de alineacion 2026-06-30: prompts/skills Pi quedaron adaptados a repo downstream; `aos-align-os-project` ahora reporta nota de registry sin editar registry manager-only, e init/adopt redirigen al upstream manager.

## Estado posterior

Main conserva docs, topics, skills e índice/audit sobre OMP nativo como registro
histórico, sin runtime, manifest ni adapter agentic local. El launcher Pi AHK
continúa como integración de producto independiente.

## Supersesión vigente (2026-08-06)

Traycer con harness nativo es la autoridad de sesión cotidiana para esta capa.
OMP queda standalone/manual y no gobierna la sesión; el launcher Pi de producto
permanece independiente.

## Referencias

- `AGENTS.md`
- `docs/WORKING_MEMORY.md`
- `docs/TOPICS.md`
- `docs/OPEN_QUESTIONS.md`
