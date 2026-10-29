#!/usr/bin/env bash
# Publica el panel de la demo y siembra sus datos. Se ejecuta en el VPS, desde la raíz del repo, después de importar-flujos.sh.
#   1. Copia demo/ a /var/www/informe-demo (Caddy no puede leer /root).
#   2. Siembra el mes de informes de ejemplo (la ruta /webhook/demo-seed solo responde en local: Caddy no la publica).
set -euo pipefail
cd "$(dirname "$0")/.."
DESTINO=/var/www/informe-demo

install -d -m 755 "$DESTINO"
install -m 644 demo/index.html "$DESTINO/index.html"
echo "Panel copiado a $DESTINO"

respuesta=$(curl -fsS -m 60 -X POST http://127.0.0.1:5678/webhook/demo-seed)
echo "Semilla: $respuesta"
