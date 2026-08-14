---
id: portable-multiharness-contract
status: active
kind: policy
triggers:
  - frontera AOS OMP
  - contrato portable
  - multi-harness
  - launcher Pi
primary_refs:
  - AGENTS.md
  - docs/topics/agentic-os-operations.md
  - docs/OS_PLAYBOOK.md
---

# Frontera Portable AOS/OMP

El contexto versionado permite continuar trabajo sin convertir a Main en un
runtime agentic ni exportar storage privado de un harness.

## Autoridad Y Límites

- **AOS local:** conserva conocimiento durable, continuidad, docs, índices,
  Working Memory, topics, tracks, specs, skills y gates propios de Main.
- **OMP:** gobierna modelos, effort, tools, browser, todos, agentes,
  planificación, paralelización, idioma, estilo y modos runtime. AOS no fija ni
  valida esas decisiones.
- **Pi:** se conserva en la integración de producto existente; sus nombres,
  presets, etiquetas, probes y runtime no se reinterpretan como control agentic.
- **Producto/servicio/lab:** scripts, datos, perfiles, sesiones y gates
  existentes conservan su ownership.

## Estado Durable Y Gates

| Superficie | Ownership |
| --- | --- |
| Contexto durable | Docs versionados, índices, Working Memory, topics, tracks y specs AOS. |
| Ejecución agentic | Harness OMP activo. |
| Skills y wrappers | Capacidades locales opt-in; no defaults cotidianos del harness. |
| Datos y configuración | Ownership del producto; preservar WIP, privacidad y gates locales. |
| Efectos externos | Installs, credenciales, destrucción, commit/push, deploy y producción requieren autorización. |

La policy documenta la frontera; no autoriza mutaciones downstream ni efectos
externos. La readiness `product_pi_runtime`, cuando exista, se conserva como
estado de producto.

Los checks estructurados pueden validar docs, links e invariantes locales, pero
no deben imponer routing OMP ni lanzar Pi/OMP, servicios, browser o efectos
externos.
