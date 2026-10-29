# Informe de turno automático (n8n)

Al acabar el turno, el operario rellena un formulario en el móvil. n8n calcula la eficiencia y las paradas, guarda el registro y manda un resumen, con un aviso si la eficiencia baja del 80 %. Cada mañana a las 07:00 llega el resumen del día anterior.

Demo con datos inventados de líneas de perfilado metálico.

## Estado

En construcción. Hecho: n8n desplegado en Docker. Pendiente: formulario, cálculos, avisos y publicación.

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
