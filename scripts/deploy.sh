#!/usr/bin/env bash
# Despliega o actualiza n8n en el VPS. Se ejecuta desde la raíz del repo clonado.
set -euo pipefail
cd "$(dirname "$0")/.."

git pull --ff-only

if [ ! -f .env ]; then
  umask 077
  cp .env.example .env
  sed -i "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)/" .env
  echo ".env creado con una clave de cifrado nueva (chmod 600)."
fi
chmod 600 .env

docker compose pull --quiet
docker compose up -d

for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:5678/healthz >/dev/null 2>&1; then
    echo "n8n responde en 127.0.0.1:5678"
    exit 0
  fi
  sleep 2
done
echo "n8n no responde tras 60 s" >&2
docker compose logs --tail 30 n8n >&2
exit 1
