#!/usr/bin/env bash
# Envía 3 informes de prueba al formulario (eficiencias del 92, 85 y 71 %), como lo haría el navegador.
# Uso en el VPS: bash scripts/probar-formulario.sh [url]  (por defecto, el n8n local)
set -euo pipefail
URL="${1:-http://127.0.0.1:5678/form/informe-turno}"
HOY=$(TZ=Europe/Madrid date +%F)

enviar() {
  # Orden de los campos: fecha, turno, línea, operario, metros, objetivo,
  # avería, cambio de formato, falta de material, otros, observaciones.
  local args=() i=0
  for v in "$@"; do args+=(-F "field-$i=$v"); i=$((i + 1)); done
  curl -fsS -X POST "${args[@]}" "$URL"
  echo
}

enviar "$HOY" "Mañana" "Perfiladora 1" "Prueba A" 4600 5000 10 25 0 5 "Prueba: turno normal"
enviar "$HOY" "Tarde" "Perfiladora 2" "Prueba B" 3400 4000 0 30 15 0 "Prueba: dos cambios de formato"
enviar "$HOY" "Noche" "Cizalla" "Prueba C" 2840 4000 65 0 40 10 "Prueba: avería en la cizalla"
