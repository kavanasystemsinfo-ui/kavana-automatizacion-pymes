# Informe de turno automático (n8n)

Al acabar el turno, el operario rellena un formulario en el móvil. n8n calcula la eficiencia y las paradas, guarda el registro y manda un resumen, con un aviso si la eficiencia baja del 80 %. Cada mañana a las 07:00 llega el resumen del día anterior.

Demo con datos inventados de líneas de perfilado metálico.

## Estado

En construcción. Ya funciona el formulario: calcula la eficiencia y las paradas y guarda cada informe en la tabla de datos `informes_turno` de n8n. Faltan los avisos, el resumen diario y la publicación del formulario.

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
