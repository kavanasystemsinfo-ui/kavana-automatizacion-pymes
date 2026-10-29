#!/usr/bin/env bash
# Carga en n8n los flujos de workflows/ y los publica. Se ejecuta en el VPS, desde la raíz del repo.
# Los flujos citan la credencial SMTP como __SMTP_ID__: aquí se sustituye por el id real,
# buscándola por su nombre. La credencial la crea una persona en el editor; este script no la toca.
# n8n solo lee los cambios de la CLI al arrancar, por eso se reinicia al final.
set -euo pipefail
cd "$(dirname "$0")/.."
CREDENCIAL_SMTP="SMTP Gmail Kavana"

smtp_id() {
  docker exec informe-turno-n8n sh -c 'n8n export:credentials --all --output=/tmp/cred.json >/dev/null 2>&1; cat /tmp/cred.json; rm -f /tmp/cred.json' |
    python3 -c "import json,sys; print(next((c['id'] for c in json.load(sys.stdin) if c['name'] == sys.argv[1] and c['type'] == 'smtp'), ''))" "$CREDENCIAL_SMTP"
}

SMTP_ID=""
if grep -lq "__SMTP_ID__" workflows/*.json; then
  SMTP_ID=$(smtp_id)
  if [ -z "$SMTP_ID" ]; then
    echo "Falta la credencial SMTP \"$CREDENCIAL_SMTP\" en n8n: créala en el editor antes de importar." >&2
    exit 1
  fi
fi

for f in workflows/*.json; do
  id=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['id'])" "$f")
  sed "s/__SMTP_ID__/$SMTP_ID/g" "$f" | docker exec -i informe-turno-n8n sh -c 'cat > /tmp/flujo.json'
  docker exec informe-turno-n8n sh -c 'n8n import:workflow --input=/tmp/flujo.json && rm -f /tmp/flujo.json'
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
