# Constelaciones smoke test — 2026-06-18

Contexto: smoke ejecutado vía Discord/Picord en `Constelaciones Interno > #pi`, workspace remoto `/home/jpsal/dev/constelaciones`.

## TL;DR / estado actual

Lo que quedó funcionando:

- Discord/Picord puede crear threads nuevos en `#pi` y responder en el workspace correcto.
- El workspace remoto detectado es `/home/jpsal/dev/constelaciones`.
- `bash` volvió a funcionar después de desactivar `pi-rtk-optimizer`.
- Los smoke tests chicos basados en docs responden bien y sirven como set de regresión rápido.
- La documentación del proyecto describe capacidades reales de WhatsApp, turnos, saldos y MercadoPago.

Lo que todavía falta solucionar:

- Algunos threads viejos o prompts amplios quedan colgados en `Thinking...` o sin cierre.
- Las consultas reales a WhatsApp por `ssh`/`wacli` no cierran confiablemente desde Discord/Picord.
- Las consultas reales a SQLite/MercadoPago disparan permisos extraños como `/constelaciones.sqlite;` aun usando rutas relativas.
- `Observational memory` falla recurrentemente con `Extension runtime not initialized`.
- Falta un smoke readonly oficial, scriptado y acotado, para consultar datos reales sin depender de prompts largos.

## Qué hicimos hoy

1. Verificamos que Discord y Picord funcionan para threads nuevos en `#pi`.
2. Confirmamos que el thread viejo `VPS smoke OK` estaba trabado, pero threads nuevos respondían.
3. Diagnosticamos que `bash` fallaba porque `pi-rtk-optimizer` reescribía comandos a `rtk` y el runtime fallaba con `/tmp/pi-rtk-optimizer`.
4. Desactivamos `pi-rtk-optimizer` en el VPS escribiendo `~/.pi/agent/extensions/pi-rtk-optimizer/config.json`.
5. Verificamos que `bash echo OK` y un comando con `pwd/date/ls` funcionaran.
6. Ejecutamos smoke tests de documentación sobre WhatsApp, MercadoPago, turnos y saldos.
7. Probamos smoke tests más ambiciosos contra datos reales; estos expusieron bloqueos pendientes de permisos/tiempos/observability.
8. Guardamos este documento como registro y runbook inicial para repetir la validación.

## Precondición reparada

Antes del smoke, `bash` fallaba porque `pi-rtk-optimizer` reescribía comandos a `rtk` y explotaba con `/tmp/pi-rtk-optimizer`. Se desactivó en VPS:

```json
{"enabled":false}
```

Verificación OK:

- `bash echo OK` → `OK`
- `bash pwd && date && ls -la docs | head -5` → ejecutó correctamente en `/home/jpsal/dev/constelaciones`.

## Resultado resumido

| Área | Resultado | Nota |
|---|---|---|
| Bash / shell | OK | Ya no reescribe a `rtk`. |
| Lectura de docs chica | OK | Tests `SMOKE-WA-02`, `SMOKE-MP-02`, `SMOKE-TURNOS-01`, `SMOKE-SALDOS-01` respondieron. |
| Inventario amplio | Inestable | `SMOKE-CONST-01` quedó sin cierre tras muchas búsquedas y permisos. |
| WhatsApp real | Inestable/Bloqueado | `SMOKE-WA-01` intentó `ssh`/`wacli`, pidió permiso externo y no cerró con reporte. |
| MercadoPago real / SQLite | Inestable/Bloqueado | `SMOKE-DATA-01` pidió permiso raro a `/constelaciones.sqlite;` y no cerró. |
| Observational memory | Falla recurrente | Varias corridas mostraron `observer failed: Extension runtime not initialized...`. |

## Hallazgos por dominio

### WhatsApp

Fuente chica: `docs/topics/whatsapp-crm.md`.

- WhatsApp histórico/local vive fuera del repo: `C:\dev\WhatsApp`.
- Producción usa VPS + `wacli` Linux + store en volumen Coolify.
- Datos reales existen en SQLite productiva del VPS: `/app/data/constelaciones.sqlite`.
- Rutas relevantes: `/admin/crm/people`, `/admin/crm/review`, `/admin/whatsapp/messages`.
- Chequeos seguros: `systemctl is-active ...timer`, `journalctl ...sync.service`, `wacli doctor`, `sqlite3 ... PRAGMA integrity_check`.
- Sync productivo: `constelaciones-whatsapp-crm-sync.timer`, cada 5 minutos.
- No hacer envíos/tandas reales sin confirmación explícita de JP/Rocío.
- No asumir frescura si Ro no está autenticada o falla el timer.

### MercadoPago

Fuente chica: `docs/topics/mercadopago-turnos.md`.

- Checkout Pro permite seña, total y saldo posterior.
- Solo webhook aprobado confirma pagos; return success/failure/pending no confirma.
- Existe pago real de prueba ARS 1 aprobado que validó `payment_request=paid`, `appointment=confirmed`, slot booked.
- Fuente local declarada: `data/constelaciones.sqlite`.
- Tablas: `payments`, `payment_requests`, `mercadopago_webhook_events`.
- Rutas públicas: `/`, `/individuales`, `/grupales`, `/saldo/<external_reference>`.
- Rutas/admin/API: `/admin/appointments`, `/admin/payments`, `/admin/credits`, `POST /api/mercadopago/preference`, `POST /api/mercadopago/webhook`.
- Bloqueos: no usar SQL manual para estados derivados; no aplicar créditos/personas sin confirmación humana; falta endurecer prod/test y validar webhook secrets.

### Turnos / reservas

Fuente chica: `docs/topics/booking-payments.md`.

- Entrada pública: `/`; reservas individuales `/individuales`; grupales `/grupales`; saldos `/saldo/<referencia>`.
- Admin: `/admin/appointments`, `/admin/events`, `/admin/payments`.
- Fuente local accesible declarada: `data/constelaciones.sqlite`.
- Tablas clave: `availability_slots`, `appointments`, `appointment_holds`, `encounters`, `encounter_registrations`, `payment_requests`, `payments`, `mercadopago_webhook_events`, `payment_whatsapp_notifications`.
- Disponibilidad pública = slots concretos, no reglas recurrentes.
- Pagos/saldos: se puede pagar seña o total; saldos por referencia.
- Conciliación debe venir del reporte oficial MercadoPago settlement/“Todas las transacciones”.
- Bloqueos: no usar `localStorage/sessionStorage`, no editar base a mano.

### Saldos / deudas / CRM follow-up

Fuente chica: `docs/topics/payment-balances-crm-followup.md`.

- Saldos se calculan desde pagos aprobados; no se editan manualmente desde UI.
- Estados: `pending_payment`, `deposit_paid`, `paid_full`, `payment_failed`.
- Si paga seña queda `balance_cents` y link público `/saldo/<external_reference>`.
- Cada reserva pública intenta asociar WhatsApp con CRM local conservadoramente.
- Contactos creados por reserva no se marcan automáticamente como clientes.
- Actividad de MercadoPago pegada manualmente debe filtrar gastos, egresos, pruebas, cancelados y personales.
- Créditos manuales persisten en `person_credit_movements`, `person_credit_applications`, `person_credit_audit_events`.
- Vista auxiliar: `/admin/credits`; aplicar crédito requiere preview + confirmación `APLICAR_CREDITO` + auditoría.

## Tests que quedaron inestables

### SMOKE-CONST-01 — inventario amplio

Prompt:

```text
SMOKE-CONST-01 inventario readonly. Relevá docs/código/fuentes disponibles para WhatsApp, turnos, saldos y Mercado Pago. No cambies nada. Respondé: capacidades, fuentes/rutas, comandos seguros y bloqueos.
```

Resultado: inició muchas lecturas/búsquedas, pidió permiso externo `/topics`, se autorizó una vez, pero no emitió cierre. Señal recurrente: `Observational memory: observer failed: Extension runtime not initialized...`.

### SMOKE-WA-01 — WhatsApp real

Prompt:

```text
SMOKE-WA-01 readonly: ¿podés consultar WhatsApp real? Si sí, buscá Rocio/Rocío últimas 2 semanas y reportá 3 hallazgos. Si no, BLOQUEADO con fuente/comando faltante.
```

Resultado: intentó usar `ssh`/`wacli`, pidió permiso externo `/usr/local/bin/wacli`, se autorizó una vez, pero no cerró con reporte. Hallazgo: consulta WhatsApp real todavía no es smokeable confiablemente vía Picord.

### SMOKE-MP-01 — MercadoPago workspace-only amplio

Prompt:

```text
SMOKE-MP-01 workspace-only, sin ssh/wacli/permisos externos: desde docs/código, ¿cómo se consultan pagos MercadoPago, rutas/scripts, datos reales accesibles? Resumen corto.
```

Resultado: leyó docs/código, luego intentó SQLite y pidió permiso externo raro `/constelaciones.sqlite`; se denegó. No cerró con resumen. Hallazgo: comandos SQLite con paths relativos pueden disparar permisos mal interpretados.

### SMOKE-DATA-01 — datos reales SQLite

Prompt:

```text
SMOKE-DATA-01 readonly: sin ssh/wacli/permisos externos. Bash solo con rutas relativas: pwd; ls -lh data/constelaciones.sqlite; sqlite3 data/constelaciones.sqlite "select count(*) from payments; select id, amount_cents, status, created_at from payments order by created_at desc limit 5;" Reportá corto o BLOQUEADO.
```

Resultado: pidió permiso externo `/constelaciones.sqlite;`, se autorizó una vez, pero no cerró. Hallazgo: smoke de datos reales requiere ajustar permisos/comando o correr desde una shell/VPS directa.

## Prompt set recomendado para futuro

Usar primero estos tests chicos; evitan búsquedas amplias y terminan mejor:

```text
SMOKE-WA-02 pequeño: leé solo docs/topics/whatsapp-crm.md. Resumí cómo consultar WhatsApp, si hay datos reales accesibles, comandos seguros y bloqueos. 8 bullets.
```

```text
SMOKE-MP-02 pequeño: leé solo docs/topics/mercadopago-turnos.md. Resumí pagos MercadoPago, consultas, datos reales accesibles, rutas y bloqueos. 8 bullets.
```

```text
SMOKE-TURNOS-01 pequeño: leé solo docs/topics/booking-payments.md. Resumí turnos, reservas, saldos, consultas, datos reales accesibles, rutas y bloqueos. 8 bullets.
```

```text
SMOKE-SALDOS-01 pequeño: leé solo docs/topics/payment-balances-crm-followup.md. Resumí saldos/deudas, seguimiento CRM/WhatsApp, datos reales, rutas y bloqueos. 8 bullets.
```

## Lo que falta solucionar

### P0 — Smoke real readonly de datos productivos

Necesitamos un camino confiable para responder preguntas reales como:

- “¿Qué pagos entraron por MercadoPago?”
- “¿Qué turnos tienen saldo pendiente?”
- “¿Qué mensajes de WhatsApp recientes hay sobre X persona?”
- “¿Este pago quedó asociado a un turno o quedó pendiente de conciliación?”

Hoy, desde Discord/Picord, esto todavía no es confiable: las pruebas reales quedaron colgadas o pidieron permisos fuera de lugar.

Acción recomendada:

1. Agregar en el repo Constelaciones un script readonly, por ejemplo `scripts/smoke-readonly.sh` o `scripts/smoke-readonly.ts`, que encapsule:
   - `pwd`, `git status --short`
   - existencia e integridad de `data/constelaciones.sqlite`
   - counts de tablas clave
   - últimos pagos MercadoPago
   - próximos turnos
   - saldos pendientes
   - estado WhatsApp timer/wacli, con timeout fuerte
   - salida compacta en Markdown o JSON.
2. Hacer que el bot ejecute **ese único script** en vez de pedirle búsquedas libres.
3. Añadir timeouts explícitos: `timeout 20s` para `ssh`, `wacli`, `sqlite3` y cualquier consulta externa.

### P0 — Permisos mal interpretados para SQLite

Síntoma:

- `SMOKE-MP-01` pidió permiso externo a `/constelaciones.sqlite`.
- `SMOKE-DATA-01` pidió permiso externo a `/constelaciones.sqlite;`.

Esto pasó aunque la intención era usar `data/constelaciones.sqlite` dentro del workspace.

Acción recomendada:

- Reproducir con un comando mínimo.
- Confirmar si el problema viene del parser de permisos, del wrapper de shell, del punto y coma final o de cómo Picord/RTK/safety parsea paths dentro de comandos quoted.
- Mientras tanto, preferir scripts versionados dentro del repo para evitar SQL inline largo en Discord.

### P0 — WhatsApp real vía VPS/wacli

Síntoma:

- `SMOKE-WA-01` intentó `ssh`/`wacli`.
- Pidió permiso externo a `/usr/local/bin/wacli`.
- Después de autorizar, no cerró con resultado.

Acción recomendada:

- Crear un comando/script readonly específico para WhatsApp:
  - `wacli doctor`
  - estado de timer/service
  - última fecha de sync
  - conteo de mensajes espejo
  - búsqueda limitada por contacto/texto, con timeout.
- Si el bot no debe tocar `wacli` directamente, exponer un script del repo que lo haga con salida sanitizada.

### P1 — Threads colgados / lifecycle Picord

Síntomas:

- Thread viejo `VPS smoke OK` no respondió a `DEBUG-01`.
- Algunos threads nuevos quedan con tool traces pero sin respuesta final.
- `/abort` en un thread trabado puede devolver “La aplicación no ha respondido”.

Acción recomendada:

- Revisar manejo de sesiones activas, `waitForRespondDone`, abort y cleanup.
- Agregar un smoke de salud Picord:
  - crear thread nuevo
  - responder OK
  - ejecutar bash corto
  - cancelar/abortar y verificar recuperación
  - revisar `activeSessions`.

### P1 — Observational memory falla durante corridas largas

Síntoma repetido:

```text
Observational memory: observer failed: Extension runtime not initialized. Action methods cannot be called during extension loading.
```

Acción recomendada:

- Reproducir con prompts amplios.
- Validar si la falla afecta solo memoria/observability o si interfiere con cierre de respuestas.
- Mientras no esté resuelto, evitar prompts amplios que disparan chunks grandes; usar prompts chicos o scripts.

### P2 — Prompts recomendados hasta tener scripts

Usar estos porque terminaron bien:

- `SMOKE-WA-02`
- `SMOKE-MP-02`
- `SMOKE-TURNOS-01`
- `SMOKE-SALDOS-01`

Evitar por ahora:

- inventarios amplios tipo `SMOKE-CONST-01`
- SQL inline largo desde Discord
- `ssh`/`wacli` directo desde prompt sin timeout y sin script wrapper
