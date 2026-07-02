---
id: minimal-implementation
status: active
kind: policy
triggers:
  - implementacion minima
  - minimal implementation
  - yagni
  - bloat
  - over-engineering
  - ponytail
primary_refs:
  - AGENTS.md
  - docs/DEVELOPMENT.md
---

# Minimal Implementation

## Politica

Preferir cambios chicos, directos y verificables. Este repo es una automatizacion personal: la solucion correcta suele ser adaptar el flujo local real, no construir framework generico.

## Reglas

- Reusar primitivas existentes (`Roa`, menu trees, chord engine) antes de crear abstracciones.
- No generalizar perfiles, paths o hotkeys personales sin senal clara.
- Mantener config local en `config.ini` y schema en `config.ini.dist`.
- Crear modulo nuevo solo si reduce acoplamiento real o encapsula una feature clara.
- Documentar convenciones nuevas solo una vez y linkear desde topics.

## Ponytail

Ponytail/criterio minimalista es capacidad opcional bajo demanda para revisar si una implementacion se puede simplificar. No reemplaza reglas de seguridad, TDD, docs ni validacion.
