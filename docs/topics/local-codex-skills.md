---
id: local-codex-skills
status: reference
kind: guide
triggers:
  - skills
  - codex skills
  - .agents
  - slash noise
  - discovery
primary_refs:
  - docs/skills/
  - scripts/ensure-skills-link.ps1
  - scripts/toggle-skills-link.ps1
---

# Local Codex Skills

`docs/skills/` es la fuente canonica local. `.agents/skills` es un junction opcional para herramientas que descubren skills desde `.agents`.

## Comandos

```powershell
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 on
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 off
```

## Politica

- Mantener discovery apagado si genera ruido en la slash palette.
- No duplicar skills como carpetas reales en `.agents/skills`.
- Si se habilita, el junction debe resolver a `docs/skills`.
