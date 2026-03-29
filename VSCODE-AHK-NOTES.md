# VSCode + AHK Notes

## Estado actual
Estamos moviendo la UX de VS Code a AutoHotkey para depender menos de keybindings y extensiones del editor.

Rutas clave:
- `C:\dev\main\code.ahk`
- `C:\dev\main\main.ahk`
- `C:\dev\main\log.txt`
- `C:\dev\main\error.txt`
- `C:\dev\vscode\controller`
- `C:\dev\skills\vscode-ahk\SKILL.md`

## Menus y hotkeys
- `Alt+G` Go
- `Alt+B` Bookmarks
- `Alt+T` Toggle
- `Alt+F` File
- `Alt+Z` Folding
- `Alt+S` Settings
- `Alt+1` Claude
- `Alt+2` Codex
- `Ctrl+Alt+X` Context probe

## Debug rapido
- AHK: `C:\dev\main\log.txt`
- AHK errores: `C:\dev\main\error.txt`
- VS Code: Output channel `VSCode Controller`
- Controller: probar `/status` y `/context`
- Recordar que algunos comandos responden `ok` pero no siempre producen foco visible si el contexto no acompana

## Proximos pasos
- Revisar por que `Alt+1` y `Alt+2` pueden loguear bien pero no producir efecto visible
- Seguir ajustando el menu `Go`
- Seguir migrando comportamiento de VS Code a AHK cuando convenga
- Usar `/context` para validar condiciones antes de nuevos hotkeys
