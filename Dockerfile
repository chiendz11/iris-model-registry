FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/mlflow
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && useradd --create-home --uid 10001 mlflow \
    && chown -R mlflow:mlflow /opt/mlflow

USER mlflow
EXPOSE 5000

CMD ["sh", "-c", "mlflow server --host 0.0.0.0 --port 5000 --backend-store-uri \"${BACKEND_STORE_URI:-postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST:-postgres}:5432/${POSTGRES_DB}}\" --artifacts-destination s3://${MLFLOW_ARTIFACT_BUCKET} --allowed-hosts '*' --cors-allowed-origins '*' "]
