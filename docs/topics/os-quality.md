---
id: os-quality
status: active
kind: checklist
triggers:
  - perfect os
  - dejar en condiciones
  - calidad agentica
  - audit
  - contexto liviano
primary_refs:
  - AGENTS.md
  - docs/WORKING_MEMORY.md
  - docs/TOPICS.md
  - scripts/agent-context-audit.ts
---

# OS Quality

Checklist para dejar la capa agentica confiable.

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

## Adapters

- `docs/skills/` es canon local.
- `.agents/skills` es junction estable de compatibilidad; si existe debe resolver a `docs/skills`.
- `.pi` debe tener prompts/extensiones `/aos-*` sincronizados.

## Seguridad

- No secretos ni estado local en git.
- No ejecutar runtime vivo sin permiso.
- No borrar memoria historica sin destino claro.

## Validacion

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
bun -e "await import('./.pi/extensions/aos-tools.ts'); console.log('aos-tools import ok')"
git diff --check
```
