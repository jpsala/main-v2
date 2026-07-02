# Local Skills

Skills locales de Agentic OS para este repo. `docs/skills/` es la fuente canonica; `.agents/skills` es solo un junction opcional para discovery en herramientas compatibles.

## Operativas

- `aos-help/`
- `aos-sigamos/`
- `aos-gol-lite/`
- `aos-guardar-sesion/`
- `aos-nueva-sesion/`
- `aos-nueva-sesion-con-gol/`
- `aos-continuar-sesion/`
- `aos-cerrar-sesion/`
- `aos-checkpoint/`
- `aos-orquestar/`
- `aos-fanout/`
- `aos-realinear-os/`
- `aos-perfect-os/`
- `aos-update-os/`
- `aos-repo-commit-push/`

## Discovery toggle

```powershell
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 on
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 off
```
