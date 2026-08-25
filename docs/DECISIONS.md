# Decisions

## 2026-08-07 — Separar conocimiento AOS de gobierno OMP

Estado: accepted

La capa AOS de Main conserva conocimiento durable, continuidad, docs, índices,
Working Memory, topics, tracks, specs, skills y gates locales. Modelos, effort,
tools, browser, todos, agentes, planificación, paralelización, idioma, estilo y
modos runtime pertenecen al harness OMP activo y no se prescriben ni validan
desde este repo.

El launcher Pi, sus presets, etiquetas, probes y runtime AHK siguen siendo una
integración de producto externa y conservan su autoridad propia.

## 2026-08-06 — Traycer con harness nativo controla la sesión

Estado: superseded el 2026-08-07 por la frontera AOS/OMP.

Historia preservada: esta decisión hacía de Traycer la autoridad cotidiana y
dejaba OMP standalone/manual. Esa política de runtime ya no está activa.

## 2026-08-04 — Usar OMP nativo y preservar el launcher Pi de producto

Estado: superseded el 2026-08-06 y reemplazado el 2026-08-07 por la frontera
AOS/OMP.

Historia preservada: la capa agentic de Main usaba intención conversacional y
capacidades nativas de OMP. El repo conserva docs, skills e índice/audit de
contexto, pero no impone runtime, manifest, package, prompts lifecycle ni
adapter agentic local. El launcher Pi de `menu-actions.ahk` y `menus.ahk` sigue
siendo una integración de escritorio externa con presets y etiquetas propios.

## 2026-06-30 — Adoptar AOS local en main-v2

`main-v2` queda registrado como proyecto activo en el manager AOS (`C:\dev\os`) y recibe una capa local adaptada: docs, topics, tracks, skills, scripts de contexto y adapter Pi.

No se copia el metasistema manager-only del upstream: registry global, decisiones internas y tracks del kit no viven aca.

## 2026-06-30 — Compactar AGENTS y mover detalle a referencia profunda

`AGENTS.md` debe ser ruta caliente corta para agentes. La guia larga anterior se preserva en `docs/reference/agent-guide-before-aos-2026-06-30.md` y el conocimiento operativo se reparte en `docs/PROJECT.md`, `docs/DEVELOPMENT.md` y topics.

## 2026-06-30 — Validacion segura para AutoHotkey vivo

No se ejecuta automaticamente `main.ahk` completo como prueba porque puede quedar residente y afectar el escritorio. Para runtime AHK, usar probes aislados o pedir permiso para pruebas manuales.

### 2026-07-04 - Preservar privacidad y gates al usar internet o instalar

Estado: accepted

Cuando una tarea consulte internet, no debe enviar secretos, `.env`, código
privado sensible, datos personales ni credenciales. La evidencia online no
reemplaza silenciosamente el repo, sus docs ni el comportamiento observado; si
los contradice, se consulta a JP con fuentes e impacto. Instalar dependencias,
CLIs, paquetes de sistema, herramientas auxiliares o binarios/scripts remotos
requiere autorización explícita con comando, alcance, riesgos y rollback.

La guía anterior sobre cuándo usar herramientas web pertenecía al gobierno del
harness y fue retirada el 2026-08-07; estos gates locales permanecen vigentes.

### 2026-07-04 - Simplificar continuidad Pi a `/aos-continuar` post-guardado

Estado: historical; superseded.

Historia preservada: AOS dejó un único comando Pi para abrir una sesión/thread
nuevo después de guardar valor durable. Los comandos previos mezclaban guardado,
handoff y ejecución. Estos comandos y el adapter Pi local fueron retirados sin
cambiar el launcher Pi de producto. La continuidad runtime ya no es política de
este repo.

## 2026-08-25 — Rerutear Ctrl+Shift+M de OMP en WezTerm

Estado: accepted

Un passthrough `~^+m` no evitó la minimización observada. Dentro de
`wezterm-gui.exe`, Main consume ahora el chord físico con `$^+m` y envía el
chord privado `Ctrl+Alt+O`, que OMP registra para su vista filtrada. Fuera de
WezTerm no cambia ningún binding.
