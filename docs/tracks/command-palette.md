---
status: active
updated: 2026-08-13
priority: high
---

# Command Palette compartida

## Estado

El renderer compartido está activo en todas las entradas. `Win+E`, `Win+A/W/C`, los siete menús de VS Code/Cursor y `Ctrl+Shift+P` de WezTerm comparten WebView, búsqueda, navegación, cierre nativo, frecency, ciclo Flat/Groups/Mixed y personalización persistente. Apps/Web/Code viven en `menu-config.json`; los árboles de VS Code/Cursor y WezTerm conservan sus fuentes declarativas y `menu-config.json` guarda sólo overrides del usuario por ID estable.

## Objetivo

Unificar búsqueda, navegación jerárquica y memoria muscular keyboard-first en una sola experiencia configurable, sin convertir archivos de preferencias en código ejecutable ni hacer que el runtime reescriba `menus.ahk`.

## Alcance actual

- `Win+E`: catálogo combinado Apps/Web/Code con frecency, navegación Flat/Groups/Mixed y personalización de los ítems canónicos.
- `Win+A/W/C`: catálogos aislados por menú y navegación híbrida; una secuencia conocida se ejecuta sin UI y una pausa o `Space` abre la paleta.
- VS Code/Cursor: Go, Bookmarks, References, Toggle, File, Folding y Settings; abren inmediatamente la WebView, registran frecency, permiten Flat/Groups/Mixed y persisten personalización como overrides sin reescribir `code.ahk`.
- WezTerm: `Ctrl+Shift+P` y clic derecho sobre `+` abren el catálogo externo de `C:\dev\wezterm\config\command-menu.json`; registran frecency, permiten Flat/Groups/Mixed y persisten personalización como overrides sin duplicar el catálogo externo. `Ctrl+Alt+Shift+P` sigue reservado a la paleta nativa de WezTerm.
- Todas las entradas comparten el mismo ciclo de ventana: `Esc` cierra y devuelve el foco a la ventana previa; pérdida de foco o click fuera cierran sin robarle nuevamente el foco a la ventana elegida.
- Inicio vacío con secciones acotadas de fijados, sugeridos por frecency y exploración.
- Personalización persistente del catálogo actual: mostrar/ocultar, eliminar, ordenar, mover de grupo, renombrar, asignar alias y fijar.
- Vista por menú: Flat, Groups o Mixed; la búsqueda escrita siempre es global, muestra primero los grupos coincidentes y luego las acciones coincidentes.
- Mantener fuera del catálogo canónico los ítems declarados `chordHidden` en la definición previa.
- Búsqueda local por nombre, alias, categoría, breadcrumb, atajo, `doc` y `command`.
- Ejecutar mediante un ID único y un `Map(id → closure)`, nunca mediante texto del input o JSON.
- Mostrar grupos por página con `Enter`/click, Backspace o `Alt+Left` para volver.
- Numerar sólo las primeras diez filas cuando la consulta está vacía; al escribir, los dígitos vuelven a ser texto.
- Restaurar foco y resetear consulta/selección al cerrar o reabrir.
- Respetar `prefers-reduced-motion` y los tokens de `ui/shared.css`.

## No objetivos

- No eliminar las definiciones de menús ni el engine Which-Key conservado para rollback.
- No ejecutar comandos arbitrarios, plugins ni código proveniente del input o de preferencias.
- No permitir acciones nuevas desde JSON en este corte; las acciones continúan en código.
- No hacer que el runtime edite archivos `.ahk`.
- No instalar dependencias ni copiar el código de PowerToys.
- No tocar `config.ini`.

## Superficies previstas

| Archivo | Cambio |
| --- | --- |
| `command-palette-catalog.ahk` | Flattening puro, datos serializables y dispatch por closure. |
| `menu-config.json` | Fuente canónica versionada para menús, ítems, chords y preferencias. |
| `command-palette-config.ahk` | Carga, validación, resolución de acciones y escritura atómica con revisión/backup. |
| `command-palette.ahk` | Hotkey y ciclo WebView con errores contenidos. |
| `command-palette-frecency.ahk` | Ranking local persistente con decaimiento exponencial de 14 días. |
| `ui/command-palette.html` | UI estilo PowerToys: búsqueda, lista, metadata, atajos y estados. |
| `main.ahk` | Include e inicialización explícita. |
| `init.ahk` | Hot reload de AHK, catálogo y HTML. |
| `tests/command-palette-*.ahk` | Catálogo, carga y bridge WebView sin diálogos. |
| `tests/command-palette-ui-probe.cjs` | Ranking fuzzy, acentos y reset de consulta. |
| `scripts/run-ahk-probe.ps1` | Runner bloqueante con timeout, stdout/stderr y exit code real. |

## Diseño de datos

Cada nodo se convierte en:

```text
{id, kind, parentId, depth, label, source, breadcrumb, shortcut, detail}
```

- `kind`: `group` o `action`.
- `parentId` y `depth`: jerarquía declarativa de `menus.ahk`, independiente de `chordPath`.
- `source`: Apps, Web o Code.
- `breadcrumb`: etiquetas de sus grupos padres.
- `shortcut`: ruta de teclas mostrada como referencia, no como identificador.
- `detail`: `doc`, `command` o descripción disponible.
- `id`: índice/namespaced path único.

Las closures de acciones se guardan por separado en `Map(id → action)`; los grupos nunca son ejecutables.

## Configuración y estado

Cuatro piezas con responsabilidades distintas:

1. `menu-config.json` es la fuente autoritativa y versionable para Apps/Web/Code. También guarda `menuOverrides` e `itemOverrides` dispersos para preferencias del usuario sobre catálogos externos, sin copiar sus árboles completos.
2. `code.ahk` y `C:\dev\wezterm\config\command-menu.json` siguen siendo las fuentes declarativas de sus propios catálogos; los overrides se aplican por ID estable al materializar cada sesión.
3. `menu-actions.ahk` y las closures existentes conservan solamente comportamiento ejecutable. El catálogo resuelve `actionId → closure`; JSON nunca contiene código ni comandos arbitrarios.
4. `%LOCALAPPDATA%\main-v2\menu-usage.json` contiene exclusivamente estado aprendido: score y último uso. Borrarlo resetea ranking sin modificar configuración.

`menu-config.json` usa `version` para migraciones de esquema y `revision` para impedir que la UI pise una edición externa. Cada guardado valida el documento completo, escribe un `.tmp`, vuelve a parsearlo, conserva `.bak` y reemplaza atómicamente. Un documento inválido no sustituye la última configuración válida en memoria.

Esquema efectivo:

```text
root: version, revision, menuOrder, menus, menuOverrides, itemOverrides
menu: shortcut, viewMode, chordMode, chordDelayMs, maxPinned, maxSuggested, groupsFirst, items
item: id, actionId?, kind, parentId, chordPath, visible, order, label, alias, pinned, pinOrder, detail?
menuOverride[source]: parámetros de experiencia modificados por el usuario
itemOverride[id]: campos estructurales modificados por el usuario o deleted
```

Los IDs son explícitos e independientes de label, orden, chord y posición. El loader rechaza IDs duplicados, parents inexistentes, ciclos, tipos inválidos, overrides inválidos y acciones sin `actionId`. Los overrides externos son dispersos: sólo guardan campos realmente cambiados y no convierten `menu-config.json` en una segunda copia de esos catálogos.

## Inicio y personalización

- Con consulta vacía y en la raíz: `Pinned`, `Suggested` y `Explore`.
- Los fijados aparecen una sola vez y quedan excluidos de sugeridos.
- Sugeridos contiene acciones con score positivo, ordenadas por frecency y acotadas por menú.
- `Ctrl+K` abre acciones sobre el ítem: pin/unpin, mover pin, mostrar/ocultar y resetear ranking.
- `Ctrl+,` abre la página de personalización del catálogo actual para ordenar, mover, renombrar, asignar alias, eliminar y ajustar parámetros del menú. Eliminar muestra junto al cursor una confirmación compacta `×`/`✓`; en grupos indica la cantidad de descendientes y los elimina en cascada. `.bak` y Git permiten recuperarlo.
- Al escribir desaparecen las secciones; fuzzy manda y frecency desempata.

## Navegación híbrida

- El prefijo abre primero una ventana de captura invisible configurable.
- Una ruta válida completa ejecuta la closure sin crear/mostrar WebView y registra uso.
- `Space` abre la paleta inmediatamente.
- Timeout abre la paleta normal.
- Una tecla que no inicia una ruta válida abre la paleta; si representa texto imprimible, se conserva como consulta inicial.
- No se muestran hints Which-Key durante esta captura híbrida.
- El modo se puede desactivar por menú para abrir siempre la paleta.

## Profundidad y drill-down

- `CommandPaletteInit()` o `CommandPaletteInit(0)`: profundidad ilimitada y lista plana actual.
- `CommandPaletteInit(1)`: muestra acciones y grupos directos; Enter/click sobre un grupo abre su página.
- `CommandPaletteInit(2)`: aplana dos niveles por página y ofrece como grupos los límites más profundos.
- `groupsFirst=false` mantiene primero todas las acciones y después los submenús; `true` invierte ambos bloques sin alterar el orden interno.
- Sin consulta se muestran las acciones y grupos de la página actual. Al escribir, la búsqueda ignora la página, muestra primero los grupos coincidentes y después filtra globalmente todas las acciones del catálogo.
- Backspace con consulta vacía, `Alt+Left` o el botón atrás suben un grupo; `Esc` siempre cierra.
- Con la consulta vacía, las primeras diez filas muestran aceleradores directos `1`–`9` y `0` para la décima. Al comenzar a escribir desaparecen: los dígitos vuelven a ser texto de búsqueda y `Enter` ejecuta el resultado activo.

## Interacción y referencia

- Ventana WebView reutilizable de 800×560, centrada en el monitor del mouse.
- Perder el foco o hacer click fuera cierra la paleta y mantiene activa la ventana elegida; `Esc` restaura la ventana desde la que se abrió.
- Input con foco al abrir; primer resultado activo.
- Filas: etiqueta principal, `source › breadcrumb`/detalle y atajo a la derecha.
- `↑/↓` navegan; `Enter`/click ejecutan acciones o abren grupos; `Esc` cancela una confirmación de borrado abierta o, fuera de ella, cierra siempre la paleta.
- El fuzzy matching resalta solo si no ensucia la lectura; no habrá animaciones cuando el sistema pida movimiento reducido.

## Cortes verificados

1. **Catálogo y hotkeys**
   - Flattening aislado y combinado, exclusión de ocultos y dispatch por closures.
   - Registros activos para `#e`, `#a/#w/#c` y siete palettes de VS Code/Cursor.
   - Registros Which-Key anteriores comentados junto al bloque activo para rollback.

2. **UI base**
   - Crear palette WebView con tokens existentes, foco, lista, contador, vacío/sin resultados y restauración de foco.
   - Probar apertura/cierre y navegación manual.

3. **Fuzzy y metadata**
   - Buscar por todos los campos, ranking estable y mostrar fuente/breadcrumb/atajo.
   - Validar consultas exactas, prefijos, acentos y subsecuencias.

4. **Smoke final**
   - Verificar `#e`, una búsqueda y acción inocua por cada fuente, Escape/click exterior y reapertura limpia.
   - Ejecutar probe, parseo JS, `git diff --check` y revisión visual contra PowerToys instalado.

## Riesgos y rollback

- El worktree ya está sucio: limitar el diff a estas superficies y no revertir cambios previos.
- Si la palette degrada un flujo, alternar exclusivamente el bloque documentado para ese grupo; nunca dejar ambos renderers registrados.
- Mantener acciones en closures locales evita ejecutar comandos arbitrarios desde el input.

## Validación

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-probe.ahk
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-frecency-probe.ahk
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-load-probe.ahk
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-webview-probe.ahk
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/vscode-command-palette-probe.ahk
node tests/command-palette-ui-probe.cjs
git diff --check
```
