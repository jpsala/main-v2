---
id: pi-agentic-os
status: active
kind: guide
triggers:
  - pi
  - slash commands
  - aos-sync
  - aos-gol
  - ask_user
  - computer use
  - rtk
primary_refs:
  - .pi/prompts/
  - .pi/extensions/
  - docs/skills/
  - scripts/context-refresh.ts
---

# Pi Agentic OS

## Recursos locales

- `.pi/prompts/aos-*.md`: prompts slash locales.
- `.pi/extensions/aos-tools.ts`: comandos como `/aos-sync`, `/aos-status`, `/aos-skills`, `/aos-gol`.
- `.pi/extensions/aos-checkpoint-nudge.ts`: nudges de checkpoint.
- `docs/skills/`: instrucciones portables detras de los comandos.

## Uso

- `aos-sigamos`: continuar en esta sesion con el siguiente paso chico.
- `aos-gol-lite`: lote chico verificable sin `/until-done`.
- `aos-guardar-sesion` / `aos-checkpoint`: guardar memoria durable en docs.
- `aos-nueva-sesion`: guardar y preparar continuidad.
- `aos-realinear-os`: auditar/reparar capa agentica local.
- `aos-orquestar` / `aos-fanout`: usar subagentes solo con valor claro o pedido de JP.

## Orquestacion Con Threads/Subagentes

Usar `spawn_agent` solo cuando JP lo pide o cuando hay paralelismo claro y seguro. Si JP no lo pidio explicitamente, pedir confirmacion con `ask_user` antes de lanzar agentes.

Guardrails:

- Mantener el hilo principal como orquestador e integrador.
- Preferir explorers read-only; workers solo con ownership no solapado por archivo/repo.
- Reservar planes, changelogs y registries externos al orquestador; workers devuelven recomendaciones.
- No paralelizar secretos, deploy/push, acciones destructivas, decisiones humanas ni refactors sobre los mismos archivos.

## ask_user

Usar dialogo estructurado cuando haya ambiguedad de producto/arquitectura, cambios irreversibles, runtime vivo, secretos, deploy o borrado de memoria.

## Computer use

El repo automatiza el escritorio real. Antes de usar CUA/GUI automation sobre runtime vivo:

- definir superficie segura o fixture;
- no tocar apps/datos reales sin permiso;
- capturar evidencia reversible;
- pedir permiso antes de acciones destructivas, envios, deploys o reinicios de automatizacion.

Infra global de computer use vive fuera del repo; no copiar configuracion MCP global como dependencia local.

## RTK

Si se usa RTK global, mantenerlo como herramienta externa/opcional. No guardar configuracion global ni outputs privados en el repo. Preferir evidencia cruda y verificable en respuestas finales.
