---
name: aos-help
description: Show the available Agentic OS (AOS) commands and when to use each one. Use when JP says `os help`, `ayuda os`, `comandos os`, or asks what command to use.
---

# OS Help

Mostrar el mapa corto de comandos AOS.

Fuente canonica: `docs/topics/os-quality.md`, seccion `Comandos Naturales`, y `docs/.generated/context-index.md` para recursos actuales.

## Respuesta

Listar comandos locales por intencion: continuar en esta sesion (`aos-sigamos`, `gol`), usar threads seguros (`aos-orquestar`, `aos-fanout`), guardar valor (`guardar sesion`), cortar contexto (`nueva sesion`, `nueva sesion con gol`), calidad OS (`realinear os`, `perfect os`), `update os` local y comandos Pi si aplican. Mostrar `aos-checkpoint`, `cerrar sesion`, `continuar sesion` y `siguiente` solo como aliases. Aclarar que init/adopt de otros repos pertenecen al upstream manager `C:/dev/os` y no a este downstream.

No ejecutar cambios salvo que JP pida un comando concreto.
