# Decisions

## 2026-06-30 — Adoptar AOS local en main-v2

`main-v2` queda registrado como proyecto activo en el manager AOS (`C:\dev\os`) y recibe una capa local adaptada: docs, topics, tracks, skills, scripts de contexto y adapter Pi.

No se copia el metasistema manager-only del upstream: registry global, decisiones internas y tracks del kit no viven aca.

## 2026-06-30 — Compactar AGENTS y mover detalle a referencia profunda

`AGENTS.md` debe ser ruta caliente corta para agentes. La guia larga anterior se preserva en `docs/reference/agent-guide-before-aos-2026-06-30.md` y el conocimiento operativo se reparte en `docs/PROJECT.md`, `docs/DEVELOPMENT.md` y topics.

## 2026-06-30 — Validacion segura para AutoHotkey vivo

No se ejecuta automaticamente `main.ahk` completo como prueba porque puede quedar residente y afectar el escritorio. Para runtime AHK, usar probes aislados o pedir permiso para pruebas manuales.
