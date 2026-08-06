---
id: os-quality
status: active
kind: checklist
triggers:
  - dejar en condiciones
  - calidad agentica
  - audit
  - contexto liviano
  - omp
primary_refs:
  - AGENTS.md
  - docs/WORKING_MEMORY.md
  - docs/TOPICS.md
  - scripts/agent-context-audit.ts
---

# Agentic Quality

Checklist para dejar la capa agentic confiable.

## Ruta caliente

- `AGENTS.md` corto.
- `docs/.generated/context-index.md` generado.
- `docs/WORKING_MEMORY.md` corto y vigente.
- `docs/TOPICS.md` como router.

## Docs

- Topics activos con frontmatter completo.
- Decisiones durables en `docs/DECISIONS.md`.
- Preguntas abiertas en `docs/OPEN_QUESTIONS.md`.
- Tracks para trabajos vivos, no transcripts.
- Referencias profundas linkeadas, no obligatorias en lectura inicial.

## Traycer + harness nativo

- `docs/skills/` es canon local y `.agents/skills` discovery estable.
- No hay runtime, manifest, package, prompt lifecycle ni extensión agentic local.
- La intención conversacional usa tools, todos y subagentes nativos del harness activo sólo cuando corresponde.
- OMP queda standalone/manual y no gobierna la sesión cotidiana.
- El audit rechaza superficies agentic legacy sin prohibir el launcher Pi de producto.

## Seguridad

- No secretos ni estado local en git.
- No ejecutar runtime vivo sin permiso.
- No borrar memoria histórica sin destino claro.
- Preservar presets, etiquetas, tests y script externo del launcher Pi.

## Validación

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
```
