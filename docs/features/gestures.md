# Gestures

## Que hay hoy

El sistema actual de gestos del repo tiene tres piezas:

- [mouse-gestures.ahk](../../mouse-gestures.ahk)
  Engine de captura, reconocimiento, replay del click, debug, shapes aprendidas y helpers base.
- [mouse-gestures-conditions.ahk](../../mouse-gestures-conditions.ahk)
  Archivo humano principal. Aca viven los `if` reales que ejecutan acciones.
- [mouse-gestures-wizard.ahk](../../mouse-gestures-wizard.ahk)
  Wizard para crear stubs, insertar nuevos `if` y ordenar bloques por especificidad.

No hay sistema de `GestureRule(...)` ni `MouseGestureQuickRegisterUsage(...)`.
La logica real vive en `mouse-gestures-conditions.ahk`.

## Regla importante

No reiniciar `main.ahk` manualmente despues de editar gestos.
`init.ahk` ya hace hot-reload en desarrollo.

## Flujo runtime

1. `main.ahk` incluye `mouse-gestures.ahk`, `mouse-gestures-wizard.ahk` y `mouse-gestures-conditions.ahk`.
2. `InitMouseGestures()` carga shapes aprendidas y shapes base.
3. El engine reconoce el gesto y construye un `event`.
4. `HandleMouseGestureQuickAction(event)` despacha a bloques por contexto.
5. Si ningun `if` matchea, se muestra debug con el gesto detectado.

## Donde tocar cada cosa

- Cambios normales de comportamiento:
  edita `mouse-gestures-conditions.ahk`
- Cambios del wizard o del ordenamiento automatico:
  edita `mouse-gestures-wizard.ahk`
- Cambios del engine, reconocimiento, thresholds, replay, debate mode, helpers base:
  edita `mouse-gestures.ahk`

## Estructura de condiciones

`mouse-gestures-conditions.ahk` esta organizado por contexto:

- `HandleOpenCodeGestures(event)`
- `HandleCodeGestures(event)`
- `HandleChromeGestures(event)`
- `HandleGlobalGestures(event)`

La funcion raiz es:

```ahk
HandleMouseGestureQuickAction(event) {
    if (HandleOpenCodeGestures(event))
        return true
    if (HandleCodeGestures(event))
        return true
    if (HandleChromeGestures(event))
        return true
    if (HandleGlobalGestures(event))
        return true
    return false
}
```

## Event disponible

`HandleMouseGestureQuickAction(event)` y todos los handlers reciben un `event` con campos como:

- `event.triggerButton`
- `event.gesture`
- `event.shapeName`
- `event.durationMs`
- `event.lengthPx`
- `event.sizeBucket`
- `event.start.x`
- `event.start.y`
- `event.end.x`
- `event.end.y`
- `event.screenRegion`
- `event.screenCell`
- `event.startMonitor`
- `event.endMonitor`
- `event.window.hwnd`
- `event.window.exe`
- `event.window.class`
- `event.window.title`

## Como escribir condiciones

Usa `gesture` cuando queres una secuencia exacta.
Usa `shapeName` cuando queres tolerar variantes.

Ejemplo simple:

```ahk
if (event.triggerButton = "RButton" && event.gesture = "D_R") {
    MouseGestureQuickSend(event, "^w", "Close tab/window")
    return true
}
```

Ejemplo por app:

```ahk
if (event.triggerButton = "MButton" && event.shapeName = "hook" && event.window.exe = "chrome.exe") {
    MouseGestureQuickSend(event, "^l", "Focus address bar")
    return true
}
```

Ejemplo por titulo:

```ahk
if (event.triggerButton = "RButton" && event.shapeName = "C" && RegExMatch(event.window.title, "OpenCode")) {
    MouseGestureQuickSend(event, "^+p", "OpenCode project command")
    return true
}
```

## Helpers utiles

### `MouseGestureQuickSend(event, keys, label)`

Helper para acciones que solo envian teclas y luego muestran feedback.

```ahk
MouseGestureQuickSend(event, "^w", "Close tab/window")
```

### `MouseGestureQuickHandled(event, label)`

Usalo cuando no envias teclas directamente pero igual queres feedback consistente.

```ahk
SetTimer(() => OpenMainBrowser(), -30)
MouseGestureQuickHandled(event, "Open main browser")
return true
```

### Reusar acciones existentes

Si el gesto debe hacer lo mismo que un hotkey existente, no mandes el hotkey con `MouseGestureQuickSend(...)` salvo que el usuario pida exactamente emular teclas.
Primero busca el hotkey y llama la funcion real que usa ese hotkey.

Ejemplo:

```ahk
; Si existe:
^+F1:: SendSelectedToWebClipboard()

; Preferi esto en el gesto:
if (event.triggerButton = "RButton" && event.gesture = "U") {
    SetTimer(() => SendSelectedToWebClipboard(), -30)
    MouseGestureQuickHandled(event, "Send selected to web clipboard")
    return true
}
```

Motivo:

- evita problemas de timing con botones del mouse todavia presionados
- evita depender de sintaxis `Send` para combinaciones complejas
- mantiene una sola fuente de verdad para la accion
- permite que el feedback del gesto sea propio

Busqueda recomendada antes de implementar:

```powershell
rg "\^\+F1|Ctrl\+Shift\+F1|F1" -g "*.ahk"
```

Si la accion del hotkey esta inline, extraela a una funcion chica y hace que tanto el hotkey como el gesto llamen esa funcion.

### `MouseGestureEventCellMatches(event, row, col, rows := 0, cols := 0)`

Chequea una sola celda de una grilla dinamica.

```ahk
MouseGestureEventCellMatches(event, 3, 1, 4, 2)
```

### `MouseGestureEventMatchesAnyCell(event, rows, cols, cells*)`

Chequea varias celdas en una misma grilla.

```ahk
MouseGestureEventMatchesAnyCell(event, 3, 3, "3,1", "3,3")
```

## Area / grilla

El engine ya expone `event.screenCell` usando la grilla default configurada.
Pero para reglas dinamicas, preferi los helpers con `rows` y `cols` explicitos.

La sintaxis del wizard para area es:

- vacio: toda la pantalla
- `1,2@2x2`
- `3,1|3,3@3x3`

Significa:

- antes de `@`: lista de celdas validas
- despues de `@`: tamaño de la grilla

Ejemplo:

```ahk
if (
    event.triggerButton = "RButton"
    && event.gesture = "D"
    && MouseGestureEventMatchesAnyCell(event, 3, 3, "3,1", "3,3")
) {
    MouseGestureQuickSend(event, "^{End}", "Go bottom corners")
    return true
}
```

## Size

`sizeBucket` se clasifica asi:

- `small` si la longitud total es menor a `120px`
- `medium` si es menor a `280px`
- `large` en adelante

## Shapes base

Las shapes base viven en `RegisterMouseGestureQuickShapes()` dentro de `mouse-gestures-wizard.ahk`.

Ejemplo actual:

```ahk
RegisterMouseGestureQuickShapes() {
    MouseGestureRegisterShape("C", ["L_D_R"])
    MouseGestureRegisterShape("square", ["U_R_D_L", "L_D_R_U"])
    MouseGestureRegisterShape("hook", ["U_R", "R_D", "L_D", "D_L"])
}
```

## Wizard

Hotkey del wizard:

- `Win+Ctrl+Alt+G`

El wizard:

- valida antes de cerrar
- si hay error, no pierde lo escrito
- copia el stub al portapapeles
- inserta el bloque en `mouse-gestures-conditions.ahk`
- abre el archivo en el bloque correspondiente

Campos principales:

- contexto
- exe opcional
- boton
- tipo `gesture` o `shape`
- valor
- size
- area
- title regex
- label
- send keys opcional

Defaults importantes:

- arranca en `Global (all)`
- `exe` vacio significa global

## Orden por especificidad

Hotkey para ordenar:

- `Ctrl+Alt+Shift+Win+G`

Funcion publica:

```ahk
MouseGestureQuickSortConditions()
MouseGestureQuickSortConditions("HandleGlobalGestures")
```

Ordena los `if` de mas especifico a menos especifico.
Tambien refresca automaticamente los comentarios `; Used:` de cada seccion.

Cuando agregues una regla mas especifica que otra ya existente, ponela antes de la regla general o corre el sorter.

Ejemplo:

```ahk
; Especifica: celda 8,8 en grilla 8x8
if (event.triggerButton = "RButton" && event.gesture = "U" && MouseGestureEventMatchesAnyCell(event, 8, 8, "8,8")) {
    ; ...
    return true
}

; General: cualquier RButton + U
if (event.triggerButton = "RButton" && event.gesture = "U") {
    ; ...
    return true
}
```

Criterios actuales:

- `gesture` antes que `shape`
- `exe`
- `titleRegex`
- `size`
- `cell`

Para `cell`:

- mas grilla y menos celdas matcheadas = mas especifico

Ejemplo:

- `"4,4"@4x4` va antes que `"4,1|4,2|4,3|4,4"@4x4`

## Comentarios `Used:`

Cada seccion de `mouse-gestures-conditions.ahk` tiene un bloque `; Used:` arriba de sus `if`.

Estado actual:

- sirven como resumen humano rapido
- se pueden regenerar a partir de los `if` reales
- `MouseGestureQuickSortConditions(...)` tambien los refresca automaticamente

Funcion publica para regenerarlos sin reordenar:

```ahk
MouseGestureQuickRefreshUsedComments()
MouseGestureQuickRefreshUsedComments("HandleGlobalGestures")
```

Pedidos utiles para el asistente:

- "ordena los gestos"
- "regenera los comentarios Used"
- "limpia los comentarios Used"
- "actualiza los comentarios Used para esta seccion"
- "documenta esta seccion de gestos"

## Aprendizaje de shapes

El engine todavia soporta aprender shapes y persistirlas en `mouse-gesture-shapes-learned.txt`.

- `#F1` inicia aprendizaje
- `#Esc` cancela aprendizaje

## Debate mode

Sirve para observar reconocimiento real sin ejecutar acciones.

- estado en `gesture-debate-state.ini`
- log en `gesture-debate-log.txt`

## Pedidos comunes que ya estan soportados

Le podes pedir al asistente cosas como:

- agregar un gesto nuevo
- mover un gesto a otro contexto
- restringir un gesto por exe, title, size o area
- ordenar los gestos por especificidad
- regenerar o limpiar comentarios `Used:`
- documentar un bloque de gestos
- crear un stub nuevo con el wizard
- hacer que los comentarios `Used:` reflejen el estado real

## Regla practica

- toca `mouse-gestures-conditions.ahk` para cambios normales
- usa `mouse-gestures-wizard.ahk` para tooling y ordenamiento
- toca `mouse-gestures.ahk` solo si queres cambiar captura, reconocimiento o dispatch
