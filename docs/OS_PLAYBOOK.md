# AOS Playbook Main

Usar `/flow` como única entrada cotidiana. Planear declara `execution_route` y
Hacer la aplica en una sesión nueva enlazada, sin Agent ni auto-send. `balanced`
con Sol Medium es la ruta normal aun para trabajo multifile, cross-layer o nativo
acotado. `strong` con Sol High queda sólo para ambigüedad material o fallos
materiales difíciles de detectar; prioridad, cantidad de archivos o un efecto
externo autorizado no bastan. `economical` con Luna requiere pedido explícito de
JP por cuota y checks deterministas. `Ctrl+P` alterna Sol Medium/High y `Ctrl+L`
conserva la selección manual. Modelo o auth ausentes bloquean sin fallback.

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
```

No iniciar `main.ahk`, automatizar escritorio, instalar, commitear, pushear o
desplegar como parte de una verificación rutinaria.
