# Traycer Native Playbook Main

Traycer con un harness nativo determina la acción cotidiana:

- conversar o investigar no implementa;
- pedir un plan produce un brief proporcional y no lo ejecuta;
- pedir implementación actúa en la sesión actual y preserva cambios existentes;
- pedir persistencia guarda sólo estado durable faltante.

Usar tools nativas mínimas suficientes. Para trabajo multietapa usar todos;
subagentes sólo por pedido explícito de JP y para slices independientes. No abrir
sesiones, crear handoffs ni autoenviar por rutina, y no añadir package, extensión,
prompt lifecycle, manifest o adapter ceremonial.

`Sol Medium` es la ruta normal. Reservar High para ambigüedad material,
arquitectura abierta, seguridad/privacidad, irreversibilidad, producción o alto
impacto. No degradar modelo, provider o auth automáticamente.

OMP queda disponible sólo como harness standalone/manual. El launcher Pi AHK
conserva su integración de producto fuera de este control plane.

El launcher Pi AHK es una integración de producto externa y conserva sus presets
y etiquetas; no define el trabajo agentic del repo.

```powershell
bun run context:index
bun run context:audit
powershell -ExecutionPolicy Bypass -File scripts/toggle-skills-link.ps1 status
```

No iniciar `main.ahk`, automatizar escritorio, instalar, commitear, pushear o
desplegar como parte de una verificación rutinaria.
