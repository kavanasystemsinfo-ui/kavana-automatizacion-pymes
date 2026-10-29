# Informe de turno automático (n8n)

Al acabar el turno, el operario rellena un formulario en el móvil. n8n calcula la eficiencia y las paradas, guarda el registro y manda un resumen, con un aviso si la eficiencia baja del 80 %. Cada mañana a las 07:00 llega el resumen del día anterior.

Demo con datos inventados de líneas de perfilado metálico.

## Estado

Funciona en producción: formulario público en https://informe.kavanasystems.com, correo por turno con aviso si la eficiencia baja del 80 % y resumen diario a las 07:00. Pendiente: datos de demo y capturas.

## Publicación

Solo el formulario sale a internet. Caddy publica `/form/*` y `/form-waiting/*`, manda la raíz al formulario y devuelve 404 para todo lo demás, editor y API incluidos (`deploy/Caddyfile.informe`). n8n sigue escuchando solo en `127.0.0.1` y genera los enlaces públicos con `N8N_WEBHOOK_URL`.

Para añadir el bloque a Caddy sin cortar el servicio:

```bash
cat deploy/Caddyfile.informe >> /etc/caddy/Caddyfile
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile --address localhost:2019
```

El formulario es abierto: cualquiera con el enlace puede enviar un informe. Si hiciera falta cerrarlo, el Form Trigger admite autenticación básica.

## Correo

Los dos flujos usan una credencial SMTP de n8n llamada `SMTP Gmail Kavana`, que se crea a mano en el editor y no está en el repo. Con Gmail: `smtp.gmail.com`, puerto 587, SSL/TLS desactivado (va por STARTTLS) y una contraseña de aplicación. Muchos proveedores de VPS, como Hetzner, bloquean la salida por los puertos 465 y 25.

- **Informe de turno**: después de guardar, envía un correo con la eficiencia, los metros frente al objetivo y las paradas por motivo. Si la eficiencia baja del 80 %, el asunto empieza por "⚠ AVISO" y el correo destaca el motivo principal. Si el correo falla, el informe queda guardado y el operario ve su confirmación igual.
- **Resumen diario de turnos**: cada día a las 07:00 (hora de Madrid) resume los informes del día anterior: por línea (turnos, metros, eficiencia, paradas y avisos), la eficiencia global y las 3 paradas más largas. Si no hubo informes, también avisa. Se puede lanzar a mano desde el editor con el nodo "Lanzar a mano".

## Flujo "Informe de turno"

Formulario → Asegurar tabla → Calcular → Guardar informe → Confirmación

- **Formulario** (`/form/informe-turno`): fecha, turno, línea, operario, metros, objetivo, minutos de parada por motivo y observaciones.
- **Asegurar tabla**: crea la tabla `informes_turno` si no existe, así el flujo funciona en una instalación nueva sin pasos a mano.
- **Calcular**: valida los datos (números no negativos, objetivo mayor que 0, paradas de 480 min como máximo) y calcula la eficiencia (metros / objetivo), las paradas totales, el motivo principal y si hay aviso (eficiencia menor del 80 %).
- **Confirmación**: el operario ve su eficiencia y sus minutos de parada.

## Cargar y probar los flujos

```bash
bash scripts/importar-flujos.sh     # importa workflows/*.json, los publica y reinicia n8n
bash scripts/probar-formulario.sh   # envía 3 informes de prueba (92, 85 y 71 %)
```

## Instalación

Requisitos: Docker con Compose, git y openssl.

```bash
git clone <este repo> && cd kavana-informe-turno
bash scripts/deploy.sh
```

`deploy.sh` crea `.env` con una clave de cifrado nueva la primera vez, arranca n8n y espera a que responda.

El editor solo escucha en `127.0.0.1:5678`. Para abrirlo desde tu equipo:

```bash
ssh -L 5678:127.0.0.1:5678 usuario@servidor
```

y luego entra en http://localhost:5678.

## Estructura

- `docker-compose.yml`: n8n con la versión fijada, un volumen persistente y logs limitados.
- `workflows/`: flujos exportados en JSON, sin credenciales.
- `scripts/deploy.sh`: despliegue y actualización.
