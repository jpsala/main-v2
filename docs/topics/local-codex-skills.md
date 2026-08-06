---
id: local-codex-skills
status: reference
kind: guide
triggers:
  - skills
  - omp skills
  - .agents
  - discovery
primary_refs:
  - docs/skills/
  - scripts/ensure-skills-link.ps1
  - scripts/toggle-skills-link.ps1
---

# Local Harness Skills

`docs/skills/` es la fuente canónica local. `.agents/skills` es la ruta estable
de discovery del harness hacia ese canon; no es un package ni runtime del proyecto.

## Comandos

```powershell
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 on
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 off
```

## Política

- No duplicar skills como carpetas reales en `.agents/skills`.
- Si existe, `.agents/skills` debe resolver por junction/symlink a `docs/skills`.
- `off` y `toggle` son aliases legacy no destructivos: el link se conserva para
  evitar rutas cacheadas rotas.
- Si aparece una carpeta real, `scripts/ensure-skills-link.ps1` la mueve a backup,
  fusiona items faltantes al canon y recrea el junction.
- Ajustar el canon o la discovery del harness, no crear prompts lifecycle,
  manifests o extensiones locales.
