---
id: pi-agentic-os
status: active
kind: guide
triggers: [pi, /flow, execution_route, ask_user, advisor, computer use]
primary_refs:
  - aos.requirements.json
  - C:/dev/os/runtime/aos-flujo.ts
  - docs/topics/agent-tool-routing.md
  - docs/reference/tool-routing.yaml
---

# Pi Agentic OS

Main consume un único `/flow` global `user/package`; no mantiene runtime, prompts
lifecycle ni comandos AOS locales.

- `Pensar` explora y converge sin implementar.
- `Planear` crea un brief liviano, declara `execution_route` y registra el foco.
- `Hacer` resuelve 0/1/N y ejecuta en una sesión nueva enlazada con handoff
  revisable, sin Agent ni auto-send.
- `Cerrar` persiste sólo valor durable faltante.

`balanced` con Sol Medium es la ruta normal, incluso para trabajo multifile,
cross-layer o nativo acotado cuando la decisión ya está tomada y hay checks
razonables. `strong` con Sol High queda sólo para ambigüedad material,
arquitectura abierta, seguridad/auth/privacidad, irreversibilidad, alto impacto
productivo o fallos materiales difíciles de detectar; prioridad, cantidad de
archivos o un efecto externo autorizado no bastan. `economical` con Luna requiere
pedido explícito de JP por cuota y checks deterministas. Modelo o auth ausentes
bloquean sin fallback. `Ctrl+P` alterna Sol Medium/High y `Ctrl+L` conserva la
selección manual. No hay Terra, clasificador extra ni routing por turno.

Este repo automatiza el escritorio real. Browser, CUA/GUI, hotkeys, clipboard,
apps o UI visible requieren aviso inicial. Cuentas, datos privados, instalaciones,
commit, push, deploy y acciones destructivas conservan los gates de `AGENTS.md`.
