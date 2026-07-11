---
id: pi-extension-stack
status: active
kind: reference
triggers:
  - extensiones pi
  - paquetes pi
  - pi packages
  - sincronizar pi
  - web_search
  - web_research
  - codemapper
  - fff
  - fffind
  - ffgrep
  - taskflow
  - pi-code-planner
  - advisor
  - pi-lens
primary_refs:
  - docs/topics/pi-agentic-os.md
  - docs/topics/agent-tool-routing.md
  - docs/reference/tool-routing.yaml
  - C:/dev/os/docs/topics/pi-extension-stack.md
---

# Pi Extension Stack

Referencia local para elegir herramientas Pi en `main`. El inventario global de
paquetes y configuracion de JP vive en `C:/dev/os/docs/topics/pi-extension-stack.md`;
no copiarlo aca como dependencia local ni duplicar settings globales.

## Regla Operativa

1. Elegir la herramienta mas chica que cierre el objetivo.
2. Usar web cuando conocimiento externo/versionado evite adivinar.
3. Antes de instalar/remover paquetes globales, pedir permiso y hacer backup de
   `C:/Users/jpsal/.pi/agent/settings.json`.
4. No tocar prod, cuentas reales, credenciales, envios, deploys ni datos privados
   sin aprobacion explicita.

## Superficie Operativa Local

| Nivel | Tools | Uso |
| --- | --- | --- |
| Core diario | `fffind`, `ffgrep`, CodeMapper (`map/search/outline`), `ask_user`, `advisor`, `lens_diagnostics` | Orientacion, decisiones humanas, segundo juicio y feedback tecnico. |
| Orquestacion | `taskflow`, council, `pi-link` si aplica | Auditorias/reviews paralelas con ownership claro; no para trabajo serial chico. |
| Piloto opt-in | `pi-dynamic-workflows` via skill upstream si esta instalado | Comparar fan-out pesado/deep research/adversarial review contra `taskflow`; no dejar triggers genericos activos. |
| Ejecucion larga | `pi-code-planner`, `/until-done`, `pi_long_task`; `pi-dgoal` solo experimental | Elegir **uno** desde `/aos-plan-implementar`; para fleet updates AOS usar `C:/dev/os` `/aos-fleet-update` -> `pi_long_task`, no `dgoal`. |
| Research externo | `web_search`, `fetch_content`, `web_answer`, `web_research`, skill `librarian` | Docs oficiales, releases, APIs, issues e internals OSS; no enviar secretos. |
| Visual/UI | `pi-chrome`, `cua-driver`, `image_generate`, `aos-impeccable` | UI/browser real; avisar batch visible y pedir permiso para cuentas reales o datos privados. |

## Planning Y Ejecucion

Usar `/aos-plan-implementar` para elegir un motor principal: manual, planner,
dgoal, until-done, long-task o taskflow. La matriz local vive en
`docs/topics/agent-tool-routing.md` y `docs/reference/tool-routing.yaml`.

- manual + Ponytail para cambios chicos;
- planner para features con stages/worktree;
- dgoal/until-done para objetivos largos acotados, nunca anidados entre si;
- long-task para TODO secuencial claro;
- taskflow/council para auditorias, reviews y fan-out.

`advisor` es gate para arquitectura/storage/prod/security, decisiones dignas de
`docs/DECISIONS.md` o loops largos. No usarlo para orientacion barata, checks o
pasos chicos de un playbook ya decidido.

## Fleet Updates AOS

Este repo es downstream. Los fleet updates multi-repo se gobiernan desde
`C:/dev/os` con `/aos-fleet-update`, que genera `pi_long_task` serial con
allowlist AOS, checks y registry upstream. No usar `dgoal` para ese caso.

## Pi Dynamic Workflows Trigger Seguro

`pi-dynamic-workflows` queda explicito-only. Default seguro global:

```json
{
  "keywordTriggerEnabled": false,
  "keywordTriggerWord": "pi-workflow"
}
```

Si aparece `[workflows mode is ON]` al escribir mensajes normales, la config
probablemente no fue parseada y el paquete volvio al trigger default `workflow`;
reescribir el JSON sin BOM, correr `/reload` y verificar `/workflows-trigger status`.

## Research / Web

- `web_search`: descubrir fuentes con 2-4 queries variadas.
- `fetch_content`: leer fuentes candidatas antes de decidir.
- `web_answer`: factual chico con grounding rapido.
- `web_research`: informe asincronico para temas amplios.
- `librarian`: internals de librerias open-source con permalinks.

No enviar secretos, `.env`, `config.ini`, datos personales ni codigo privado
sensible a servicios externos.
