---
id: project-architecture
status: active
kind: guide
triggers:
  - arquitectura
  - include graph
  - main.ahk
  - init.ahk
  - hot reload
  - config.ini
  - webview
primary_refs:
  - main.ahk
  - init.ahk
  - docs/PROJECT.md
  - docs/DEVELOPMENT.md
---

# Project Architecture

## Runtime model

- `main.ahk` es el entrypoint y raiz del grafo de includes.
- `init.ahk` carga config local, valida paths, arma launchers de navegador, inicializa timers y hot reload.
- Los modulos AHK incluidos tienen efectos de carga: tratar `#Include` como orden de ejecucion.
- WebView2 se usa para settings, menus, hints y otras superficies HTML locales.

## Include order sensible

Al agregar un modulo:

1. Verificar dependencias ya cargadas.
2. Incluirlo en `main.ahk` en un punto seguro.
3. Evitar top-level code nuevo salvo inicializacion revisada.
4. Si se edita durante desarrollo, agregarlo a `filesToCheckForReload` en `init.ahk`.

## Config

- `config.ini`: real/local; puede tener rutas y bookmarks privados.
- `config.ini.dist`: schema portable.
- `.env`: local/secreto; no versionar.

Si una feature necesita config nueva, agregar clave a `config.ini.dist` y manejar default/missing path sin romper startup.

## WebView pattern

- AHK: ventana/lifecycle/WebMessage/posicionamiento.
- HTML: render e interaccion.
- Compartido: `ui/shared.css` y `ui/ahk-bridge.js`.
- Para ventanas custom sin caption, HTML debe proveer titlebar/drag-bar y controles si aplica.

## Validacion segura

No correr `main.ahk` completo automaticamente. Usar probes aislados o pedir permiso para prueba manual.
