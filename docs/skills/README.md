# Local Skills

Skills locales de Agentic OS para este repo. `docs/skills/` es la fuente
canonica; `.agents/skills` es solo un junction de compatibilidad para discovery
en herramientas compatibles.

## Regla

- No duplicar skills en dos carpetas reales.
- `.agents/skills` debe apuntar por junction a `docs/skills/` cuando exista.
- `off` y `toggle` son aliases legacy no destructivos; no borrar el junction para
  evitar paths cacheados rotos.
- Si se agrega o modifica una skill, editar `docs/skills/<nombre>/`.
- Si una skill cambia comportamiento durable, documentarlo tambien en topics,
  working memory o decisiones.

## Contenido Actual

- `aos-gol-lite/`: ejecutar el proximo lote chico y verificable sin activar un
  loop autonomo pesado.

Las skills AOS portables removidas de este downstream se consultan en
`C:/dev/os/docs/skills/`; no duplicarlas localmente. Las herramientas Pi de
pensamiento/implementacion (`taskflow`, planner, `advisor`, Ponytail, `dgoal`,
`until-done`, `pi-lens`) se documentan en `docs/topics/pi-extension-stack.md` y
`docs/topics/agent-tool-routing.md`, no como skills locales separadas.

## Validacion

```powershell
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
powershell -ExecutionPolicy Bypass -File scripts/ensure-skills-link.ps1
bun run context:index
bun run context:audit
```

## Mantenimiento

- Si una skill nueva usa metadata UI, crear o regenerar `agents/openai.yaml`.
- Si un doc humano apunta a `.agents/skills` como fuente de verdad, corregirlo a
  `docs/skills/`.
- Si Codex/Pi deja de descubrir skills, reparar primero la junction antes de
  tocar contenido: `bun run skills:on`.
- Tras mover o portar el repo a otro disco, correr `scripts/ensure-skills-link.ps1`.
