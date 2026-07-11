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

`docs/skills/` es la fuente canonica local. `.agents/skills` es solo una ruta de
compatibilidad para herramientas que descubren skills desde `.agents`.

## Comandos

```powershell
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 on
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 off
```

## Politica

- No duplicar skills como carpetas reales en `.agents/skills`.
- Si existe, `.agents/skills` debe resolver por junction/symlink a `docs/skills`.
- `off` y `toggle` son aliases legacy no destructivos: el link se conserva para
  evitar paths cacheados rotos en Pi/Codex.
- Si aparece una carpeta real, correr `scripts/ensure-skills-link.ps1`; el script
  la mueve a backup, fusiona items faltantes al canon y recrea el junction.
- Si Pi muestra demasiado ruido en slash, ajustar visibilidad/config del host; no
  borrar el canon ni romper la ruta de compatibilidad.
