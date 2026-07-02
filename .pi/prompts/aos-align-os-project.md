---
description: Alinear la capa AOS local de este repo downstream
---
Ejecuta `aos-align-os-project` para este repo downstream: revisar la capa agentica local, usar `C:/dev/os` solo como fuente upstream de patrones portables cuando haga falta, y no copiar ni editar registry manager-only (`docs/OS_PROJECTS.md`). No pisar memoria local ni tocar producto/datos/deploy sin confirmacion. Regenerar indice/audit del repo, correr checks seguros y reportar aplicado, omitido, conflictos, drift restante, evidencia y una nota de registry para que el orquestador la consolide fuera de este repo.
