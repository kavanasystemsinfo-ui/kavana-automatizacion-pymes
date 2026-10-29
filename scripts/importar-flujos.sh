#!/usr/bin/env bash
# Carga en n8n los flujos de workflows/ y los publica. Se ejecuta en el VPS, desde la raíz del repo.
# n8n solo lee los cambios de la CLI al arrancar, por eso se reinicia al final.
set -euo pipefail
cd "$(dirname "$0")/.."

for f in workflows/*.json; do
  id=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['id'])" "$f")
  docker exec informe-turno-n8n n8n import:workflow --input="/$f"
  docker exec informe-turno-n8n n8n publish:workflow --id="$id"
  echo "Publicado: $f ($id)"
done

docker compose restart n8n
for i in $(seq 1 30); do
  curl -fsS -o /dev/null http://127.0.0.1:5678/healthz 2>/dev/null && { echo "n8n listo"; exit 0; }
  sleep 2
done
echo "n8n no responde tras el reinicio" >&2
exit 1
