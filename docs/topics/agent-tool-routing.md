---
id: agent-tool-routing
status: active
kind: how-to
triggers:
  - tool routing
  - routing decision
  - combinar tools
  - elegir herramienta
  - dgoal
  - until-done
  - taskflow
  - advisor
  - ask_user
primary_refs:
  - docs/reference/tool-routing.yaml
  - docs/topics/pi-agentic-os.md
  - docs/topics/pi-extension-stack.md
  - C:/dev/os/docs/skills/aos-plan-implementar/SKILL.md
  - .pi/extensions/aos-tools.ts
---

# Agent Tool Routing

Contrato operativo local para elegir y combinar herramientas Pi sin pisarse. La
regla base: **un motor gobierna; las demas herramientas apoyan**.

## Routing Decision

Para trabajos medianos/grandes, declarar antes de implementar:

```text
Routing Decision
- Intent: discuss | study | spec | plan | implement | review
- Primary engine: manual | planner | dgoal | until-done | long-task | taskflow | pi-dynamic-workflows (solo piloto opt-in)
- Why: escenario de docs/reference/tool-routing.yaml que matchea
- Support tools: advisor | ask_user | lens | web | librarian | council | taskflow
- Forbidden nesting: combinaciones que no se van a iniciar
- Required gates: ask_user/advisor/lens/checks
- Verification: comando/check/evidencia de cierre
```

Si el trabajo es chico y reversible, basta una linea: `Routing: manual, porque
es cambio chico; validar con <check>`.

## Matriz Corta

| Escenario | Motor principal | Apoyos | Gate |
| --- | --- | --- | --- |
| Cambio chico/reversible | manual | Ponytail si aplica, lens, checks | ninguno |
| Feature grande con stages/TDD | planner | advisor, lens, checks | advisor si cambia arquitectura |
| Objetivo largo por fases | dgoal | taskflow read-only, advisor, lens | dgoal_check por fase |
| Loop con verify command claro | until-done | advisor, lens, checks | verify command |
| TODO secuencial claro | long-task | checks | ask_user si costo/side effects |
| Fleet update AOS serial | long-task via `C:/dev/os` `/aos-fleet-update` | checks, git, registry upstream | commits solo si JP los pidio; no push |
| Auditoria/review/fan-out | taskflow o council | advisor si decision fuerte | workers read-only por defecto |
| Fan-out pesado experimental/benchmark | pi-dynamic-workflows | taskflow baseline, advisor | opt-in explicito y trigger seguro |
| Research externo/versionado | manual/research | web_search, fetch_content, web_answer, librarian | no secretos/datos privados |
| Prod/deploy/envios/datos/destructivo | el que corresponda | ask_user | confirmacion explicita |

La version verificable vive en `docs/reference/tool-routing.yaml`.

## Routing GPT-5.6

| Trabajo | Modelo / esfuerzo |
| --- | --- |
| Pi normal y planificacion compacta | Sol medium |
| Planificacion, arquitectura, advisor y conformidad | Sol high |
| Trabajo mecanico barato | Luna medium |
| Implementacion background acotada | Luna xhigh; retry con Luna max |
| Implementacion interactiva sensible a latencia | Terra high |
| Trabajo de alta garantia | Terra max; validar con Sol xhigh |

Tests, conformidad y riesgo prevalecen sobre las heuristicas de costo. Los
cambios de settings requieren reload o una sesion nueva cuando aplique.

## Reglas Locales

- `advisor` se reserva para arquitectura/storage/prod/security, decisiones
  dignas de `docs/DECISIONS.md` o loops largos. No usarlo para orientacion
  barata, checks, ni pasos chicos de un playbook ya decidido.
- `ask_user` se usa para producto/arquitectura ambiguos, instalaciones,
  credenciales, prod/deploy, commits/push, datos privados o acciones
  destructivas.
- `taskflow`/council sirven para paralelismo real con ownership claro; el
  orquestador integra y escribe.
- `pi-dynamic-workflows` es piloto opt-in, no reemplazo default de `taskflow` ni
  trigger generico `workflow`.
- Fleet updates AOS viven en el upstream `C:/dev/os` y usan `pi_long_task` /
  `/aos-fleet-update`; no usar `dgoal` para ese caso.

## Nesting Prohibido

- `dgoal` como default para fleet updates AOS.
- `dgoal -> until-done` o `until-done -> dgoal`.
- `planner -> dgoal/until-done` salvo decision explicita de migrar de motor.
- `taskflow detached -> taskflow detached`.
- `pi-dynamic-workflows` como modo permanente, trigger generico o reemplazo de
  `taskflow`.
- Dos branches paralelas escribiendo los mismos archivos.
- Desktop/browser automation con cuentas/canales reales sin `ask_user`.

## Si Hay Duda

Elegir la opcion mas chica que no pierda seguridad:

```text
manual < long-task < until-done < planner < taskflow/council
```

Si dos motores parecen igual de buenos, usar `ask_user` o `advisor`, pero no
activar dos motores principales a la vez.
