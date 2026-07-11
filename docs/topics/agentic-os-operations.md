---
id: agentic-os-operations
status: active
kind: how-to
triggers:
  - aos
  - realinear os
  - auditar sistema agentico
  - reparar sistema agentico
  - actualizar os
  - adoptar os
  - contexto agentico
primary_refs:
  - AGENTS.md
  - docs/WORKING_MEMORY.md
  - docs/TOPICS.md
  - docs/.generated/context-index.md
  - docs/skills/
  - scripts/context-index.ts
  - scripts/agent-context-audit.ts
---

# Operaciones AOS Locales

## Alcance

Este repo es un downstream AOS: recibe una capa local de contexto, docs, skills, scripts y adapter Pi. No copiar registry global ni decisiones/tracks internos de `C:\dev\os`.

Por defecto, `realinear os` toca solo capa agentica. No cambiar runtime AHK, config real, datos, shortcuts ni automatizacion viva salvo pedido explicito.

## Lectura minima

1. `AGENTS.md`
2. `docs/.generated/context-index.md`
3. `docs/WORKING_MEMORY.md`
4. `docs/TOPICS.md`
5. `docs/tracks/`
6. Este topic

## Revisar

- Ruta caliente corta y actual.
- Topics con frontmatter, triggers y refs existentes.
- Tracks activas con status/updated/next step.
- `docs/skills/` como canon local.
- `.agents/skills` como junction estable de compatibilidad; `off`/`toggle` son aliases legacy no destructivos.
- `.pi/prompts` y `.pi/extensions` con comandos `/aos-*`.
- Routing de herramientas en `docs/topics/agent-tool-routing.md` y `docs/reference/tool-routing.yaml`.
- Scripts `context-index.ts`, `agent-context-audit.ts`, `context-refresh.ts`.
- Docs raiz historicos con destino claro.

## Corregir sin preguntar

- Links rotos obvios.
- Indice generado stale.
- Frontmatter/triggers faltantes.
- Compactar ruta caliente sin perder contenido (mover a referencia profunda si hace falta).
- Actualizar `WORKING_MEMORY.md` con estado vivo real.

## Preguntar antes

- Borrar memoria/documentos historicos.
- Mover archivos raiz si su destino no es claro.
- Tocar `config.ini`, `.env`, logs privados o runtime AHK.
- Reiniciar o ejecutar automatizacion viva.

## Cierre

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
bun -e "await import('./.pi/extensions/aos-tools.ts'); console.log('aos-tools import ok')"
git diff --check
```

Reportar aplicado, omitido, pendientes y evidencia.
