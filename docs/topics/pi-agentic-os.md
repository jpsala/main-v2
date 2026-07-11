---
id: pi-agentic-os
status: active
kind: guide
triggers:
  - pi
  - slash commands
  - aos-sync
  - aos-gol
  - aos-continuar
  - aos-plan-implementar
  - ask_user
  - taskflow
  - advisor
  - pi-lens
  - computer use
  - web research
  - internet
  - instalar paquetes
  - instalar cli
primary_refs:
  - .pi/prompts/
  - .pi/extensions/
  - docs/skills/
  - docs/topics/pi-extension-stack.md
  - docs/topics/agent-tool-routing.md
  - docs/reference/tool-routing.yaml
  - scripts/context-refresh.ts
---

# Pi Agentic OS

Adapter Pi local para `main`. La fuente de verdad sigue siendo el repo
(`AGENTS.md`, `WORKING_MEMORY`, topics, tracks y decisiones); Pi aporta slash
commands, prompts, tools y compaction controlada.

## Web, Internet E Instalaciones

- Usar web/internet libremente por defecto cuando conocimiento externo o
  cambiante evite adivinar: documentacion oficial, changelogs/releases,
  issues/source, metadata de paquetes, errores, APIs, ejemplos y comparativas.
- Si evidencia online contradice el repo local, docs del proyecto o
  comportamiento observado, pausar y consultar a JP con fuentes e impacto.
- No enviar secretos, `.env`, `config.ini`, codigo privado sensible, datos
  personales ni credenciales a servicios externos.
- Antes de instalar dependencias, CLIs globales, paquetes de sistema,
  herramientas de package-manager o binarios/scripts remotos, pedir autorizacion
  explicita con comando, alcance, motivo, riesgos, alternativas, cambios y
  rollback.

## Comandos Pi Locales

- `.pi/prompts/aos-*.md`: prompts slash locales.
- `.pi/extensions/aos-tools.ts`: `/aos-status`, `/aos-sync`, `/aos-skills`,
  `/aos-compact`, `/aos-continuar`, `/aos-plan-implementar`.
- `.pi/extensions/aos-checkpoint-nudge.ts`: nudges de checkpoint.
- `docs/skills/`: instrucciones portables detras de los comandos.

| Comando | Uso |
| --- | --- |
| `/aos-help` | Mostrar comandos AOS locales. |
| `/aos-guardar-sesion`, `/aos-checkpoint`, `/aos-cerrar` | Persistir valor durable sin transcript. |
| `/aos-continuar [objetivo]` | Abrir sesion nueva con prompt desde docs vivos despues de guardar. |
| `/aos-plan-implementar` | Crear/revisar plan y elegir un motor principal. |
| `/aos-status [audit]` | Estado git/contexto/audit. |
| `/aos-sync` | Ensure skills link, regenerar indice y correr audit. |
| `/aos-skills status|on|off|toggle` | Ver/reparar `.agents/skills`; `off`/`toggle` son aliases legacy no destructivos. |
| `/aos-compact [foco]` | Compactacion manual OS-aware. |
| `/aos-orquestar`, `/aos-fanout` | Fan-out controlado con taskflow/subagentes. |
| `/aos-evaluar-skills` | Auditar skills/prompts/extensiones. |

## Strategy Gate

Usar `/aos-plan-implementar` para trabajos medianos/grandes. Elegir **un** motor:
manual, planner, dgoal, until-done, long-task o taskflow. No anidar motores sin
explicitar por que.

La fuente local de combinacion es `docs/topics/agent-tool-routing.md`; la policy
verificable vive en `docs/reference/tool-routing.yaml`.

Heuristica corta:

- cambio chico: manual + Ponytail si aplica + checks;
- investigacion externa/versionada: web/librarian sin secretos;
- decision fuerte: `advisor()` antes de arquitectura/storage/prod/security,
  decisiones `DECISIONS.md`-worthy o loops largos; no para orientacion barata,
  checks o pasos chicos de un playbook ya decidido;
- fleet update AOS serial: desde `C:/dev/os` usar `/aos-fleet-update` ->
  `pi_long_task`; no `dgoal`;
- auditoria/review/fan-out: `taskflow` o council si el paralelismo vale el costo;
- codigo tocado: `lens_diagnostics`/LSP como feedback y checks del repo como gate.

## Routing GPT-5.6

Sol medium es el default para Pi normal y planificacion compacta; usar Sol high
para planificacion, arquitectura, advisor y conformidad. Luna medium cubre
trabajo mecanico barato; implementacion background acotada usa Luna xhigh, con
retry Luna max. Para implementacion interactiva sensible a latencia usar Terra
high. Trabajo de alta garantia usa Terra max y validacion Sol xhigh. Tests,
conformidad y riesgo prevalecen sobre costo. Los cambios de settings requieren
reload o una sesion nueva cuando aplique.

## Human-in-the-loop

Usar `ask_user`/`ask_user_question` cuando hay decision de producto,
arquitectura, credenciales, permisos, instalaciones, prod/deploy, acciones
destructivas o contradiccion internet-vs-local. No preguntar lo inferible ni
encadenar modales.

## Browser / Computer Use

Este repo automatiza el escritorio real. Browser signed-in, CUA/GUI automation,
hotkeys, clipboard, apps o UI visible requieren aviso inicial para un batch
coherente. No tocar cuentas reales, canales, pagos, prod ni datos privados sin
confirmacion explicita.

## Orquestacion

Usar taskflow/council cuando haya paralelismo real, ownership claro y retorno
comprimido. El orquestador integra y verifica; workers empiezan read-only salvo
plan aprobado.

## Flujo Recomendado

1. Leer ruta liviana: index -> working memory -> TOPICS -> topic puntual.
2. Inspeccionar git antes de editar.
3. Elegir herramienta con `docs/topics/pi-extension-stack.md`.
4. Ejecutar el corte mas chico verificable.
5. Si se tocaron docs: `bun run context:index` y `bun run check`.
6. Guardar valor durable en docs; no transcript.

## Portabilidad

`.pi/` es adapter opcional. Este downstream referencia `C:/dev/os` para inventario
global, routing/fleet upstream y aprendizajes portables; no copia registry,
settings globales ni inventarios de JP.
