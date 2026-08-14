# AOS Local Playbook Main

La capa AOS local mantiene contexto durable y recuperable; no coordina el
runtime agentic.

## Ruta De Contexto

1. Leer `docs/.generated/context-index.md`.
2. Continuar por `docs/WORKING_MEMORY.md` y `docs/TOPICS.md`.
3. Abrir sólo el topic, track o spec relevante.
4. Preservar WIP y promover a docs únicamente conocimiento que deba sobrevivir.

## Frontera

- AOS conserva docs, índices, Working Memory, topics, tracks, specs, skills y
  gates locales.
- OMP gobierna modelos, effort, tools, browser, todos, agentes, planificación,
  paralelización, idioma, estilo y modos runtime.
- Main no mantiene una política ni un validador de routing del harness.
- Skills, extensiones, wrappers y scripts opt-in siguen permitidos cuando
  aportan una capacidad local real y no se convierten en defaults cotidianos.

## Gates Locales

- No tocar `.env`, `config.ini`, logs ni datos privados salvo pedido explícito.
- No iniciar `main.ahk`, automatizar el escritorio, instalar, commitear,
  pushear o desplegar como verificación rutinaria.
- El launcher Pi AHK es producto externo y conserva presets, etiquetas, probes
  y runtime.

## Checks Recomendados

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
```
