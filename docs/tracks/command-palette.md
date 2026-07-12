---
status: active
updated: 2026-07-11
priority: high
---

# Command Palette (`Win+E`)

## Estado

V1 implementada y verificada: abre con `Win+E`, cataloga comandos A/W/C, ejecuta una acción real, `Esc` cierra y la reapertura limpia la consulta. `Win+A/W/C` volvieron a los menús convencionales which-key. `CommandPaletteInit(levelsPerPage := 0, groupsFirst := false)` permite drill-down y orden por tipo. Las acciones y sus grupos padres aprenden orden por frecency local con una vida media de 14 días; la búsqueda conserva fuzzy como criterio principal.

## Objetivo

Agregar una command palette personal, inspirada en PowerToys Command Palette, que busque y ejecute las acciones existentes de los menús A/W/C. La palette reemplaza temporalmente sus hotkeys directos durante la evaluación.

## Alcance V1

- Registrar exclusivamente `#e` (`Win+E`).
- Catalogar grupos y acciones de `GetMainSeqAOptions()`, `GetMainSeqWOptions()` y `GetMainSeqCOptions()`; con `levelsPerPage=0` mostrar las acciones finales planas como antes.
- Excluir `chordHidden`, CopyQ, bookmarks y chords contextuales de VS Code.
- Búsqueda local por nombre, categoría, breadcrumb, atajo, `doc` y `command`.
- Ranking fuzzy estable: exacto, prefijo, inicio de palabra, consecutivo y subsecuencia; normalizar mayúsculas y acentos.
- Ejecutar mediante un id único y un `Map(id → closure)`, no concatenando teclas.
- Interacción completa por teclado: input, flechas, Enter, Esc, click, contador y estado sin resultados.
- Restaurar foco y resetear consulta/selección al cerrar o reabrir.
- Respetar `prefers-reduced-motion` y los tokens de `ui/shared.css`.

## No objetivos

- No eliminar las definiciones de los menús A/W/C; `Win+A/W/C` conservan sus registros which-key.
- No historial visible, favoritos, plugins, comandos arbitrarios, CopyQ ni acciones de VS Code.
- No instalar dependencias ni copiar el código de PowerToys.
- No commit/push ni tocar `config.ini`.

## Superficies previstas

| Archivo | Cambio |
| --- | --- |
| `command-palette-catalog.ahk` | Flattening puro, datos serializables y dispatch por closure. |
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

## Profundidad y drill-down

- `CommandPaletteInit()` o `CommandPaletteInit(0)`: profundidad ilimitada y lista plana actual.
- `CommandPaletteInit(1)`: muestra acciones y grupos directos; Enter/click sobre un grupo abre su página.
- `CommandPaletteInit(2)`: aplana dos niveles por página y ofrece como grupos los límites más profundos.
- `groupsFirst=false` mantiene primero todas las acciones y después los submenús; `true` invierte ambos bloques sin alterar el orden interno.
- La búsqueda filtra solo las acciones y grupos visibles en la página actual; para encontrar una acción más profunda hay que abrir su submenú.
- Backspace con consulta vacía, `Alt+Left` o el botón atrás suben un grupo; `Esc` siempre cierra.

## Interacción y referencia

- Ventana WebView reutilizable de 800×480, centrada en el monitor del mouse como PowerToys.
- Input con foco al abrir; primer resultado activo.
- Filas: etiqueta principal, `source › breadcrumb`/detalle y atajo a la derecha.
- `↑/↓` navegan; `Enter`/click ejecutan acciones o abren grupos; `Esc` cancela.
- El fuzzy matching resalta solo si no ensucia la lectura; no habrá animaciones cuando el sistema pida movimiento reducido.

## Plan por cortes verificables

1. **Catálogo y hotkey**
   - Implementar flattening de A/W/C, exclusión de ocultos y Map de dispatch.
   - Registrar `#e` y restaurar los registros which-key `#a/#w/#c`.
   - Probe AHK para rutas, IDs, ocultos y ejecución de una closure de prueba.

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
- Si la palette degrada el escritorio, quitar el registro `#e`; `#a/#w/#c` conservan sus menús which-key.
- Mantener acciones en closures locales evita ejecutar comandos arbitrarios desde el input.

## Validación

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-probe.ahk
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-frecency-probe.ahk
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-load-probe.ahk
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/command-palette-webview-probe.ahk
node tests/command-palette-ui-probe.cjs
git diff --check
```
