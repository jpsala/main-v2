---
id: portable-multiharness-contract
status: active
kind: policy
triggers:
  - contrato portable
  - multi-harness
  - Traycer
  - OMP standalone
  - handoff bajo demanda
  - worktree
primary_refs:
  - docs/topics/agent-tool-routing.md
  - docs/topics/agentic-os-operations.md
  - docs/reference/tool-routing.yaml
---

# Contrato Portable Multi-Harness

Este repo puede continuar desde Traycer o desde OMP standalone usando únicamente
el contexto versionado del repo. El contrato no exporta epics, artifacts,
sesiones ni storage de Traycer y no convierte a OMP en un runtime del proyecto.

## Autoridad Y Límites

- **Traycer:** ruta cotidiana para intención, planificación y ejecución con un
  harness soportado nativamente. No se agrega un selector ni un adapter AOS
  paralelo.
- **OMP:** harness standalone, deliberado y manual. Puede continuar desde un
  handoff corto y explícito sin leer `.traycer` ni depender de un epic.
- **Pi:** se conserva sólo en la integración de producto existente; no es la
  entrada cotidiana ni un harness anidado de Traycer.
- **Producto/servicio/lab:** nombres, scripts, datos, perfiles, sesiones y gates
  Pi/OMP existentes conservan su ownership y no se reinterpretan como AOS.
- **`.traycer`:** no es dependencia del repo, fuente portable ni requisito de
  sus checks.

## Gates Y Estado Durable

| Superficie | Binding portable | Gate |
| --- | --- | --- |
| Intención y plan | Conversación del harness activo; artifacts sólo en el epic Traycer | Planear no ejecuta sin pedido explícito. |
| Shell y checks | Comandos declarados por el repo | Preservar WIP y gates locales. |
| Browser y tools | Capacidad nativa del harness activo | Login o efecto externo sensible conserva su gate. |
| Estado durable | Docs versionados y Git | Promover sólo decisiones que deban sobrevivir al epic. |
| Efectos | Ownership y política local | Installs, credenciales, destrucción, commit/push, deploy y producción requieren autorización. |

La policy documenta compatibilidad, no autoriza mutaciones downstream ni efectos
externos. La readiness registrada `product_pi_runtime`, cuando exista, se
conserva y no se reemplaza por una inferencia narrativa de Traycer.

## Ownership Y Handoff

- Una tarea secuencial usa un único escritor en el workspace actual y un handoff
  explícito sólo si otro harness necesita continuar.
- Simultaneidad, revisión fría o riesgo de contaminación requieren ramas y
  worktrees separados con ownership claro.
- El handoff es un resumen corto, no un transcript ni una copia de artifacts:

```text
objetivo: <resultado observable>
rama/worktree: <rama y workspace, o "actual">
decisiones: <decisiones relevantes>
cambios/estado observable: <archivos o estado verificable>
checks: <checks y resultado>
siguiente gate: <próximo gate o "ninguno">
```

El repo debe poder operar con este contrato sin leer `.traycer`. Los checks
estructurados validan la policy, pero no lanzan Pi/OMP, servicios, browser ni
efectos externos.
