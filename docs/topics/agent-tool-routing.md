---
id: agent-tool-routing
status: active
kind: how-to
triggers: [tool routing, /flow, execution_route, advisor, ask_user]
primary_refs:
  - docs/reference/tool-routing.yaml
  - docs/topics/pi-agentic-os.md
---

# Agent Tool Routing

Main sigue la política global flow-first. `balanced` con Sol Medium es la ruta
normal, incluso para trabajo multifile, cross-layer o nativo acotado cuando la
decisión ya está tomada y hay checks razonables. `strong` con Sol High queda sólo
para ambigüedad material, arquitectura abierta, seguridad/auth/privacidad,
irreversibilidad, alto impacto productivo o fallos materiales difíciles de
detectar. Prioridad, cantidad de archivos, stack nativo, contrato/review,
planificación compleja o un efecto externo ya autorizado no bastan. `economical`
con Luna requiere pedido explícito de JP por cuota y checks deterministas. Hacer
aplica la ruta en la sesión nueva; modelo o auth ausentes bloquean sin fallback.
`Ctrl+P` alterna Sol Medium/High y `Ctrl+L` conserva la selección manual.

CodeMapper/FFF orientan; Lens/LSP diagnostican; Advisor aporta criterio; web
investiga; Ask User controla gates. No son motores alternativos. Taskflow,
Council, planner, until-done, dgoal y aliases lifecycle están retirados.

Automatización desktop, hotkeys, clipboard, procesos, cuentas y datos reales
conservan los gates de `AGENTS.md`. La policy verificable vive en
`docs/reference/tool-routing.yaml`.
