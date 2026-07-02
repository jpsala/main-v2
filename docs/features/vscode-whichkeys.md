# VS Code Whichkeys

## Qué resuelve

Esta feature organiza acciones frecuentes de VS Code y Cursor en chords con prefijo. La idea es evitar recordar demasiados shortcuts sueltos y, al mismo tiempo, no depender de un menú visual permanente: disparás un prefijo, aparece el hint, elegís una tecla y se ejecuta un comando del editor.

En tu forma de trabajo, esta es la zona correcta cuando digas algo como:

- "Quiero refactorizar los whichkeys de VS Code"
- "Tengo demasiadas opciones y no uso todas"
- "Quiero agrupar mejor los comandos"
- "Quiero que el árbol sea más claro"

## Qué hace hoy

Los launchers visibles están definidos al principio de [code.ahk](../../code.ahk):

- `Alt+G` inicia el chord de navegación/go
- `Alt+B` inicia el chord de bookmarks
- `Alt+T` inicia el chord de toggles
- `Alt+S` inicia el chord de settings
- `Alt+Z` inicia el chord de folding
- `Alt+F` inicia el chord de file actions

Además hay algunos accesos directos relacionados:

- `Alt+1` enfoca Claude
- `Alt+2` enfoca Codex Chat
- `Ctrl+Alt+X` muestra un context probe del controlador

## Archivos clave

- [code.ahk](../../code.ahk)
  Acá viven los launchers `Alt+...`, los helpers HTTP al controlador de VS Code, los builders de opciones de cada chord y `InitVSCodeControllerChords()`.
- [lib/chord-hotkeys.ahk](../../lib/chord-hotkeys.ahk)
  Engine genérico de chords, timeouts, hints, submenús y ejecución.
- [menus-whichkey.ahk](../../menus-whichkey.ahk)
  Bridge reutilizable que convierte estructuras de opciones en registros para el engine de chords.
- [ui/chord-hint.html](../../ui/chord-hint.html)
  UI del hint overlay.

## Cómo está armado

El flujo general es este:

1. Un hotkey como `Alt+G` llama a `VSCode_StartGoChord()`.
2. Ese helper libera `Alt`, registra logging y deriva en `VSCode_StartChord(...)`.
3. `VSCode_StartChord(...)` dispara un prefijo real del engine, por ejemplo `^!g`.
4. `InitVSCodeControllerChords()` registra cada prefijo mediante `MenuWhichKeyRegisterWithActions(...)`.
5. Las opciones de cada chord salen de funciones tipo `GetVSCodeGoChordOptions()`.
6. Cada item ejecuta `VSCode_RunCommand(...)` o `VSCode_RunCommandSequence(...)`.
7. El controlador HTTP de VS Code/Cursor recibe el comando y lo ejecuta.

## Prefijos actuales

Los prefijos reales registrados hoy en [code.ahk](../../code.ahk) son:

- `^!g` para navegación y foco
- `^!b` para bookmarks
- `^!c` para referencias
- `^!t` para toggles
- `!f` para acciones de archivo
- `^!z` para folding
- `^!s` para settings

Los launchers más amigables para vos son los `Alt+...`, pero internamente el engine trabaja con esos prefijos reales.

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

Hoy es el chord más cargado y probablemente el mejor candidato a simplificación.

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

Si querés reorganizar el árbol, casi todo el trabajo debería pasar por [code.ahk](../../code.ahk), especialmente por estas funciones:

- `GetVSCodeGoChordOptions()`
- `GetVSCodeBookmarksChordOptions()`
- `GetVSCodeReferencesChordOptions()`
- `GetVSCodeToggleChordOptions()`
- `GetVSCodeFileChordOptions()`
- `GetVSCodeFoldingChordOptions()`
- `GetVSCodeSettingsChordOptions()`
- `InitVSCodeControllerChords()`

Normalmente no haría falta tocar el engine en [lib/chord-hotkeys.ahk](../../lib/chord-hotkeys.ahk) para una limpieza de opciones. Ese archivo entra en juego solo si querés cambiar comportamiento general del sistema de chords:

- timeouts
- hint delay
- navegación entre submenús
- render del overlay
- manejo de teclas inválidas o `Esc`

## Estrategias de refactor posibles

Cuando quieras ordenar estos whichkeys, hay varias direcciones razonables:

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
- mete ruido en un chord que ya está saturado

## Cómo me podés pedir cambios

Estos pedidos ya alcanzan para arrancar:

- "Quiero limpiar `Alt+G`"
- "Quiero que `Alt+T` tenga menos opciones"
- "Quiero mover comandos de chat fuera de `Alt+G`"
- "Quiero dejar solo lo que uso en Cursor"
- "Quiero separar navegación de AI/chat"

## Gotchas

- Los launchers amigables `Alt+...` no son los mismos prefijos que registra el engine.
- Algunas opciones dependen del controlador HTTP de VS Code en `http://127.0.0.1:7777`.
- Varias acciones son personales o históricas, así que no conviene asumir que todas siguen teniendo valor.
- Antes de tocar el engine general, conviene intentar resolver el problema solo reorganizando opciones en [code.ahk](../../code.ahk).
