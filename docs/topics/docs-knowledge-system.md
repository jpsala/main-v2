---
id: docs-knowledge-system
status: active
kind: how-to
triggers:
  - docs
  - documentacion
  - topics
  - memoria
  - context index
  - guardar sesion
  - tracks
primary_refs:
  - docs/README.md
  - docs/WORKING_MEMORY.md
  - docs/TOPICS.md
  - docs/.generated/context-index.md
  - docs/tracks/
---

# Docs Knowledge System

## Objetivo

Dar a agentes una ruta corta para entender el repo sin abrir analisis enormes ni transcripts.

## Ruta caliente

1. `docs/.generated/context-index.md`
2. `docs/WORKING_MEMORY.md`
3. `docs/TOPICS.md`
4. Topic/doc puntual

## Donde guardar conocimiento

- Regla critica para agentes: `AGENTS.md`.
- Estado vivo: `docs/WORKING_MEMORY.md`.
- Tema reusable: `docs/topics/<id>.md`.
- Decision durable: `docs/DECISIONS.md`.
- Pendiente humano: `docs/OPEN_QUESTIONS.md`.
- Trabajo vivo retomable: `docs/tracks/<track>.md`.
- Detalle largo/historico: `docs/reference/` o archivo raiz historico ya existente, linkeado desde `TOPICS.md`.

## Higiene

- No convertir docs en transcript.
- No duplicar contenido: linkear refs profundas.
- Mantener `docs/TOPICS.md` como router humano y `docs/.generated/context-index.md` como cache generado.
- Regenerar indice despues de cambiar topics/tracks/skills/pi.

## Comandos

```powershell
bun run context:index
bun run context:audit
bun run context:refresh
```
