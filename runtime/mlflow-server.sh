#!/bin/sh
set -eu

if [ -n "${BACKEND_STORE_URI:-}" ]; then
  backend_store_uri=${BACKEND_STORE_URI}
else
  : "${POSTGRES_USER:?POSTGRES_USER is required when BACKEND_STORE_URI is unset}"
  : "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required when BACKEND_STORE_URI is unset}"
  : "${POSTGRES_HOST:?POSTGRES_HOST is required when BACKEND_STORE_URI is unset}"
  : "${POSTGRES_DB:?POSTGRES_DB is required when BACKEND_STORE_URI is unset}"
  backend_store_uri=$(
    python - <<'PY'
import os
from urllib.parse import quote

user = quote(os.environ["POSTGRES_USER"], safe="")
password = quote(os.environ["POSTGRES_PASSWORD"], safe="")
host = os.environ["POSTGRES_HOST"]
port = os.getenv("POSTGRES_PORT", "5432")
database = quote(os.environ["POSTGRES_DB"], safe="")
print(f"postgresql://{user}:{password}@{host}:{port}/{database}")
PY
  )
fi

: "${MLFLOW_ARTIFACT_BUCKET:?MLFLOW_ARTIFACT_BUCKET is required}"
: "${MLFLOW_ALLOWED_HOSTS:?MLFLOW_ALLOWED_HOSTS must explicitly list trusted Host headers}"
: "${MLFLOW_CORS_ALLOWED_ORIGINS:?MLFLOW_CORS_ALLOWED_ORIGINS must be explicit}"

exec mlflow server \
  --host 0.0.0.0 \
  --port "${PORT:-5000}" \
  --workers "${MLFLOW_WORKERS:-2}" \
  --backend-store-uri "${backend_store_uri}" \
  --artifacts-destination "s3://${MLFLOW_ARTIFACT_BUCKET}" \
  --allowed-hosts "${MLFLOW_ALLOWED_HOSTS}" \
  --cors-allowed-origins "${MLFLOW_CORS_ALLOWED_ORIGINS}"
