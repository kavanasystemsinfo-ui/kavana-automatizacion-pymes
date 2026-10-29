#!/usr/bin/env bash
# Envía solicitudes de prueba al formulario de ausencias, como lo haría el navegador.
# Uso en el VPS: bash scripts/probar-ausencias.sh [url]  (por defecto, el n8n local)
# Orden de los campos: empleado, tipo, desde, hasta, comentario.
# La solicitud válida deja una ejecución esperando la respuesta de la responsable (botones del correo).
set -euo pipefail
URL="${1:-http://127.0.0.1:5678/form/rrhh-ausencias}"

enviar() {
  local args=() i=0
  for v in "$@"; do args+=(-F "field-$i=$v"); i=$((i + 1)); done
  local respuesta espera pagina="" intento
  respuesta=$(curl -fsS -X POST "${args[@]}" "$URL")
  espera=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['formWaitingUrl'])" "$respuesta")
  espera="${URL%%/form/*}/form-waiting/${espera#*/form-waiting/}"
  for intento in $(seq 1 12); do
    pagina=$(curl -fsS -m 5 "$espera" 2>/dev/null) && break
    sleep 1
  done
  [ -n "$pagina" ] || { echo "La confirmación no llegó en 1 minuto" >&2; return 1; }
  grep -oE '(No se puede tramitar|Solicitud enviada)' <<<"$pagina" | head -1
  grep -oE '(Pides|Esas fechas|La fecha final|Ya tienes|Marta|Iván|Laura)[^<"]{0,140}' <<<"$pagina" | head -1
  curl -fsS -m 15 -o /dev/null -X POST "$espera"
}

enviar "Marta Soler" "Vacaciones" "2026-11-22" "2026-11-21" "Prueba: fechas al revés"
enviar "Marta Soler" "Vacaciones" "2026-11-21" "2026-11-22" "Prueba: fin de semana"
enviar "Marta Soler" "Vacaciones" "2026-11-16" "2026-11-18" "Prueba: tres días de vacaciones"
