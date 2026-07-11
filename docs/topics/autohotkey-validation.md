---
id: autohotkey-validation
status: active
kind: guide
triggers:
  - autohotkey
  - ahk
  - probe
  - runtime error
  - webview
primary_refs:
  - scripts/run-ahk-probe.ps1
  - tests/command-palette-probe.ahk
  - tests/command-palette-load-probe.ahk
  - tests/command-palette-webview-probe.ahk
---

# AutoHotkey Validation

Protocolo obligatorio para evitar falsos positivos, procesos residentes y dialogos de error durante cambios AHK.

## Por que

- `/ErrorStdOut` captura errores de carga, pero los errores runtime de AHK v2 pueden abrir dialogos.
- Invocar `AutoHotkey64.exe` directamente desde PowerShell puede devolver control antes de que termine el proceso; ese `$LASTEXITCODE` no prueba nada.
- `main.ahk` es automatizacion viva y residente, no un test runner.

## Diseno testeable

1. Separar logica pura de hotkeys, timers, hooks, WebView y top-level runtime.
2. Incluir en cada probe solo la superficie minima.
3. Mantener closures en AHK y exponer al JSON solo IDs y datos serializables.
4. `JsonDump` acepta `Map` y `Array`, no object literals.
5. Recordar que los identificadores AHK no distinguen mayusculas; una variable puede sombrear una funcion nativa.

## Contrato de un probe

- `#ErrorStdOut "UTF-8"` para errores de carga.
- `OnError(...)` para contener errores no capturados.
- `try/catch` alrededor del escenario.
- Fallos escritos a stderr con mensaje y stack.
- `ExitApp(0)` al pasar y `ExitApp(1)` al fallar.
- `#Warn All, StdOut` en probes enfocados; si includes legacy producen warnings ajenos, desactivarlo solo para esas dependencias.

Ejecutar exclusivamente con:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-ahk-probe.ps1 -Script tests/<probe>.ahk
```

El runner espera el proceso real, captura stdout/stderr, aplica timeout, valida el exit code y elimina procesos residuales. Un probe que falla no debe mostrar ventanas.

## Escalera de validacion

1. Probe de carga/sintaxis del modulo.
2. Logica pura, IDs, closures y round-trip JSON.
3. JavaScript aislado si existe UI HTML.
4. Bridge WebView real en un probe aislado.
5. Esperar hot reload; nunca reiniciar `main.ahk` manualmente.
6. Confirmar un unico proceso `main.ahk`, sin procesos de probe y sin errores nuevos en `log.txt`.
7. Smoke fisico del hotkey, `Esc`, reapertura limpia y una accion inocua real.

Si el runtime no esta vivo o aparece evidencia contradictoria, detenerse y consultar a JP; no arrancar `main.ahk` para compensarlo.
