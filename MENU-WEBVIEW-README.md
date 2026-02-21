# Sistema de Menús con WebView

## Descripción

Sistema de menús alternativo que usa WebView2 para mostrar una interfaz filtrable con navegación por teclado completa. Combina lo mejor de ambos mundos:

- **Ejecución inmediata por teclado**: Si presionas la tecla antes del timeout, se ejecuta el comando directamente sin mostrar la UI
- **UI filtrable con WebView**: Si no presionas tecla o el timeout expira, aparece una ventana con búsqueda fuzzy, navegación con flechas y Enter

## Características

✅ **Navegación híbrida**: Keyboard-first con fallback a UI visual  
✅ **Filtrado en tiempo real**: Escribe para filtrar opciones  
✅ **Soporte de submenús**: Con breadcrumbs y navegación jerárquica  
✅ **Atajos de teclado**:
- `↑/↓` - Navegar opciones
- `Enter` - Seleccionar
- `Esc` - Cerrar (o retroceder en submenús)
- `Backspace` (con input vacío) - Retroceder un nivel

✅ **Dark theme**: Tema oscuro consistente con VS Code  
✅ **Sin mouse necesario**: Completamente navegable por teclado

## Archivos del Sistema

- **[menu-webview.ahk](menu-webview.ahk)** - Módulo principal con la lógica
- **[ui/menu.html](ui/menu.html)** - Interfaz WebView con estilo y JavaScript
- **[menus.ahk](menus.ahk)** - Incluye los menús de test integrados (Win+- hotkeys)
- **[menu-webview-example.ahk](menu-webview-example.ahk)** - Ejemplos adicionales opcionales

## Uso Básico

### 1. Reemplazar `customMenu()` por `customMenuWebView()`

```ahk
; ANTES (menú tradicional)
#a:: {
    options := {
        waitml: 800,
        items: [
            { key: 'c', label: 'Calculator' },
            { key: 's', label: 'Spotify' },
        ]
    }
    key := customMenu(options)
    
    switch key {
        case 'c': Run('calc.exe')
        case 's': Run('spotify.exe')
    }
}

; DESPUÉS (menú WebView)
#a:: {
    options := {
        waitml: 800,
        title: "Apps",  ; Opcional: título de la ventana
        items: [
            { key: 'c', label: 'Calculator' },
            { key: 's', label: 'Spotify' },
        ]
    }
    key := customMenuWebView(options)
    
    if (!key) return  ; Usuario canceló
    
    switch key {
        case 'c': Run('calc.exe')
        case 's': Run('spotify.exe')
    }
}
```

### 2. Estructura de Options

```ahk
options := {
    waitml: 800,           ; Milisegundos para execution inmediata
    title: "Mi Menú",      ; (Opcional) Título de la ventana
    items: [               ; Array de items del menú
        { key: 'c', label: 'Calculator' },
        { key: 's', label: 'Spotify', items: [  ; Submenu
            { key: 'w', label: 'Web Player' },
            { key: 'd', label: 'Desktop App' }
        ]},
    ]
}
```

### 3. Activar los Ejemplos

Los menús de test ya están disponibles directamente:
- `Win+-` - Menú completo de test con submenús
- `Win+Shift+-` - Menú simple de test  
- `Win+Ctrl+-` - Menú largo de test con 30 items

Para activar los ejemplos adicionales opcionales, agrega en [main.ahk](main.ahk):

```ahk
#Include ".\menu-webview-example.ahk"
```

Luego podrás usar:
- `Win+Shift+A` - Menú de apps con WebView
- `Win+Shift+W` - Menú web/browser con WebView  
- `Win+Shift+C` - Menú código/dev con WebView

## Comportamiento Detallado

### Fase 1: Keyboard-First (0-800ms)

Cuando activas el menú (ej: `Win+A`):

1. El sistema espera `waitml` milisegundos (default: 800ms)
2. Si presionas una tecla válida → **ejecuta inmediatamente**
3. La tecla puede ser para un item directo o para entrar a un submenú
4. Si es un submenú, se repite el proceso

**Ejemplo:**
- Presionas `Win+A`
- Dentro de 800ms presionas `s` → Ejecuta Spotify de inmediato
- O presionas `t` luego `t` → Ejecuta Terminal de inmediato

### Fase 2: WebView UI (después del timeout)

Si no presionas nada en 800ms:

1. Aparece la ventana WebView con todos los items
2. El input tiene foco automáticamente
3. Puedes filtrar escribiendo
4. Navegas con `↑↓` y seleccionas con `Enter`
5. Para submenús:
   - Aparece indicador `►` a la derecha
   - Al seleccionar, entra al submenú
   - Muestra breadcrumb arriba
   - `Esc` o `Backspace` para volver atrás

## Integración con Menús Existentes

Puedes convertir gradualmente tus menús actuales:

### Opción A: Mantener ambos sistemas

```ahk
; Menú original con customMenu
#a:: mainSeqA()

; Menú WebView alternativo
#+a:: mainSeqAWebView()

mainSeqAWebView() {
    ; Misma estructura de options que mainSeqA()
    options := { ... }
    
    key := customMenuWebView(options)  ; <-- Solo cambiar esta línea
    
    ; Mismo switch que mainSeqA()
    switch key { ... }
}
```

### Opción B: Reemplazar completamente

```ahk
#a:: mainSeqA()

mainSeqA() {
    options := { ... }
    
    ; Cambiar solo esta línea:
    ; key := customMenu(options)
    key := customMenuWebView(options)
    
    if (!key) return  ; Agregar validación
    
    switch key { ... }
}
```

## Comparación: customMenu vs customMenuWebView

| Característica | customMenu | customMenuWebView |
|----------------|------------|-------------------|
| Ejecución inmediata | ✅ | ✅ |
| Timeout configurable | ✅ | ✅ |
| Fallback visual | Menu nativo | WebView |
| Filtrado/búsqueda | ❌ | ✅ |
| Navegación teclado | Limitada | Completa (↑↓) |
| Submenús | ✅ | ✅ con breadcrumbs |
| Retronavegación | N/A | ✅ (Esc/Backspace) |
| Tema oscuro | Sistema | ✅ Personalizado |
| Dependencias | Nativas | WebView2 (incluido) |

## Notas Técnicas

### Inicialización

El WebView se inicializa la primera vez que se usa. Puede haber un pequeño delay (< 1s) en la primera apertura.

### Formato de Keys

- Las keys se concatenan: padre + hijo
- Ejemplo: menú `s` → submenú `w` = key `"sw"`
- Case-sensitive según definido en items

### Valor de Retorno

- String con la key seleccionada (ej: `"c"`, `"tw"`, `"scd"`)
- `false` si usuario canceló (Esc o cerró ventana)

### Performance

- Primer uso: ~500-1000ms (inicialización WebView)
- Usos subsiguientes: ~50-100ms (instántaneo)
- El WebView permanece en memoria (oculto) para reaperturas rápidas

## Troubleshooting

### El menú no aparece

1. Verifica que `ui/menu.html` existe
2. Verifica que WebView2 está instalado (viene con Windows 11, Edge o Cursor)
3. Revisa el output con `OutputDebug` para errores

### Las teclas no funcionan en keyboard mode

- Verifica que `waitml` está configurado (> 0)
- Las keys deben coincidir exactamente (case-sensitive)
- Usa Window Spy (`Win+A` → `y`) para debug

### El filtro no funciona

- Asegúrate que el input tiene foco (debería ser automático)
- Prueba hacer click en el input si es necesario
- El filtro busca en key y label

## Personalización

### Cambiar tamaño de ventana

En [menu-webview.ahk](menu-webview.ahk), función `ShowWebViewMenu()`:

```ahk
w := 450  ; Ancho
h := 400  ; Alto
```

### Cambiar posición

```ahk
y := mt + (mb - mt - h) // 3  ; Cambiar divisor para posición vertical
```

### Cambiar estilos

Edita [ui/menu.html](ui/menu.html), sección `<style>`:

```css
:root {
  --bg-primary: #1E1E1E;    /* Fondo principal */
  --bg-active: #094771;      /* Item seleccionado */
  --accent: #007ACC;         /* Color de acentos */
  /* ... más variables ... */
}
```

## TODO / Mejoras Futuras

- [ ] Soporte para íconos en items
- [ ] Fuzzy matching avanzado (no solo includes)
- [ ] Scoring de relevancia en resultados
- [ ] Historial de selecciones recientes
- [ ] Shortcuts directos desde el input (ej: `/calc` ejecuta directamente)
- [ ] Themes personalizables desde config
- [ ] Animaciones suaves de transición

## Test Menus

En [menus.ahk](menus.ahk) hay 3 menús de test integrados:

- **`Win+-`** → Menu completo con submenús multinivel
- **`Win+Shift+-`** → Menu simple sin submenús (8 opciones)
- **`Win+Ctrl+-`** → Menu largo con 30 items (prueba scrolling)

## Licencia

Parte del proyecto main.ahk. Usa WebViewToo.ahk (MIT License).
