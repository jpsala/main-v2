---
id: agent-tool-routing
status: active
kind: how-to
triggers: [tool routing, routing decision, Traycer, OMP standalone, intención, todos, subagentes]
primary_refs:
  - docs/reference/tool-routing.yaml
  - docs/OS_PLAYBOOK.md
---

# Agent Tool Routing

Traycer con harness nativo interpreta la intención conversacional:

- conversar o investigar no edita;
- pedir un plan produce un brief proporcional, sin ejecutarlo;
- pedir implementación actúa en la sesión actual y preserva cambios existentes;
- pedir persistencia guarda sólo valor durable faltante.

Usar las tools mínimas suficientes. Para trabajo multietapa usar todos; subagentes
sólo por pedido explícito de JP y para slices independientes. El hilo principal
integra y verifica. No abrir otra sesión, crear handoff ni autoenviar por rutina;
el handoff sólo se genera bajo demanda para OMP standalone.

`Sol Medium` es la ruta normal. High queda para ambigüedad material, arquitectura
abierta, seguridad/privacidad, irreversibilidad, producción o alto impacto. No
degradar modelo, provider o auth automáticamente.

Automatización desktop, hotkeys, clipboard, procesos, cuentas y datos reales
conservan los gates de `AGENTS.md`. El launcher Pi AHK es una integración de
producto externa y sus presets no seleccionan el harness agentic del repo. La
política verificable vive en `docs/reference/tool-routing.yaml` y el contrato
portable en `docs/topics/portable-multiharness-contract.md`.
