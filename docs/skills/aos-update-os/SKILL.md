---
name: aos-update-os
description: Update an existing downstream AOS installation against upstream portable AOS patterns, bringing only applicable local runtime pieces and never copying AOS manager-only context. Use when JP says `update os`, `actualiza el os`, or asks to update/improve/audit an AOS repo.
---

# Update OS

Actualizar una capa AOS existente contra patrones portables del upstream canonico.

Fuente canonica: `docs/topics/agentic-os-operations.md`, seccion `Update`.

Comparar por capas: docs/scripts locales, skills, Codex `.agents`, Pi `.pi`, Claude/otros adapters si existen, SpecKit si aplica, indice y audit. Fusionar sin pisar memoria local, omitir piezas manager-only de AOS (`OS_PROJECTS`, decisiones/tracks/memoria del kit, inventarios globales) y reportar capas aplicadas u omitidas.
