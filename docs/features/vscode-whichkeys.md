# VS Code Command Palettes

## Qué resuelve

Esta feature organiza acciones frecuentes de VS Code y Cursor en palettes contextuales por área. Cada launcher abre una lista jerárquica con aceleradores `1`–`9`/`0`; al escribir, la búsqueda abarca globalmente todas las acciones de esa palette.

Usar esta guía para pedidos como:

- "Quiero refactorizar las palettes de VS Code"
- "Tengo demasiadas opciones y no uso todas"
- "Quiero agrupar mejor los comandos"
- "Quiero que el árbol sea más claro"

## Qué hace hoy

Los launchers visibles están definidos al principio de [code.ahk](../../code.ahk):

- `Alt+G` abre navegación/go
- `Alt+B` abre bookmarks
- `Alt+T` abre toggles
- `Alt+S` abre settings
- `Alt+Z` abre folding
- `Alt+F` abre file actions

`Ctrl+Alt+C` abre References directamente.

Además hay algunos accesos directos relacionados:

- `Alt+1` enfoca Claude
- `Alt+2` enfoca Codex Chat
- `Ctrl+Alt+X` muestra un context probe del controlador

## Archivos clave

- [code.ahk](../../code.ahk)
  Contiene launchers `Alt+...`, helpers HTTP, builders de opciones, registros activos de palettes y el bloque Which-Key comentado para rollback.
- [menus-whichkey.ahk](../../menus-whichkey.ahk)
  Adapta cualquier `options.items` a un catálogo aislado y registra la Command Palette compartida.
- [command-palette-catalog.ahk](../../command-palette-catalog.ahk)
  Materializa grupos, acciones, IDs, breadcrumbs y closures sin mezclar catálogos.
- [ui/command-palette.html](../../ui/command-palette.html)
  UI jerárquica numerada y búsqueda fuzzy global.

## Cómo está armado

1. Un hotkey como `Alt+G` llama a `VSCode_StartGoChord()`.
2. El helper libera `Alt` y deriva en `VSCode_StartChord(...)`.
3. Si existe un launcher activo en `VSCode_ControllerPaletteLaunchers`, abre su palette preconstruida.
4. `InitVSCodeControllerChords()` registra los siete catálogos mediante `MenuCommandPaletteRegisterWithActions(...)`.
5. Las opciones siguen saliendo de funciones tipo `GetVSCodeGoChordOptions()`.
6. Cada hoja ejecuta `VSCode_RunCommand(...)` o `VSCode_RunCommandSequence(...)`.
7. El controlador HTTP de VS Code/Cursor recibe el comando y lo ejecuta.

## Prefijos internos

Los registros internos conservados son:

- `^!g` para navegación y foco
- `^!b` para bookmarks
- `^!c` para referencias
- `^!t` para toggles
- `!f` para acciones de archivo
- `^!z` para folding
- `^!s` para settings

Los launchers amigables siguen siendo `Alt+...`; el mapa interno permite que esos wrappers abran la misma palette que el hotkey registrado.

## Árbol actual por áreas

### `Alt+G`

Orientado a navegación, foco y accesos rápidos a chats/herramientas:

- terminal, editor, explorer, source control, problems
- go to line, quick open view, forward/back
- subgrupo `FindJump`
- subgrupo `Codex`
- subgrupo `Claude`
- subgrupo `Copilot`
- accesos rápidos `1`, `2`, `3`

Hoy es la palette más cargada y probablemente la mejor candidata a simplificación.

### `Alt+B`

Orientado a bookmarks de la extensión:

- toggle bookmark
- list bookmarks
- list all files
- toggle labeled bookmark

### `Alt+T`

Orientado a toggles de layout y vista:

- side bars
- terminal/panel
- maximize panel
- word wrap
- continue console
- reopen with editor
- markdown preview y related setting

### `Alt+F`

Orientado a acciones de archivos:

- create/new file
- advanced new file
- compare with clipboard
- copy relative path
- close all editors

### `Alt+Z`

Orientado a folding:

- fold level at cursor
- fold/unfold
- toggle fold
- recursive fold/unfold

### `Alt+S`

Orientado a settings:

- user settings JSON
- project settings
- settings UI
- application settings
- abrir varias settings juntas
- folder settings
- keyboard shortcuts JSON/UI

## Qué conviene tocar cuando querés refactorizar

La estructura vive en [code.ahk](../../code.ahk), especialmente en:

- `GetVSCodeGoChordOptions()`
- `GetVSCodeBookmarksChordOptions()`
- `GetVSCodeReferencesChordOptions()`
- `GetVSCodeToggleChordOptions()`
- `GetVSCodeFileChordOptions()`
- `GetVSCodeFoldingChordOptions()`
- `GetVSCodeSettingsChordOptions()`
- `InitVSCodeControllerChords()`

Para cambiar navegación, búsqueda o aceleradores, tocar la Command Palette compartida, no los builders.

Para rollback visual, comentar el bloque `VSCode_ControllerPaletteLaunchers[...]` y descomentar el bloque `MenuWhichKeyRegisterWithActions(...)` inmediatamente anterior. Mantener exactamente un renderer activo.

## Estrategias de refactor posibles

Cuando quieras ordenar estas palettes, hay varias direcciones razonables:

- `podar`
  Sacar opciones que ya no usás.
- `aplanar`
  Reducir subniveles y dejar menos branching.
- `reagrupar`
  Mover acciones a otro prefijo más lógico.
- `separar por frecuencia`
  Dejar arriba lo diario y mandar lo raro a subgrupos.
- `renombrar`
  Cambiar labels para que el árbol se lea más rápido.

Mi recomendación inicial para tu caso sería:

- limpiar primero `Alt+G`
- revisar después `Alt+T`
- dejar `Alt+B`, `Alt+F`, `Alt+Z` y `Alt+S` casi como están salvo que detectemos ruido claro

## Criterio práctico para decidir si algo se queda

Una opción debería quedarse si cumple al menos una de estas:

- la usás seguido
- cuesta recordar el command name de VS Code
- ahorra varios pasos
- encaja claramente en el árbol actual

Una opción es candidata a salir o mudarse si:

- no la usás casi nunca
- solo existe "por si acaso"
- duplica otra ruta
- obliga a memorizar una letra poco intuitiva
- mete ruido en una palette que ya está saturada

## Cómo me podés pedir cambios

Estos pedidos ya alcanzan para arrancar:

- "Quiero limpiar `Alt+G`"
- "Quiero que `Alt+T` tenga menos opciones"
- "Quiero mover comandos de chat fuera de `Alt+G`"
- "Quiero dejar solo lo que uso en Cursor"
- "Quiero separar navegación de AI/chat"

## Gotchas

- Los launchers amigables `Alt+...` usan prefijos internos para compartir el mismo callback registrado.
- Algunas opciones dependen del controlador HTTP de VS Code en `http://127.0.0.1:7777`.
- Varias acciones son personales o históricas, así que no conviene asumir que todas siguen teniendo valor.
- Antes de tocar la UI compartida, conviene intentar resolver el problema reorganizando opciones en [code.ahk](../../code.ahk).
