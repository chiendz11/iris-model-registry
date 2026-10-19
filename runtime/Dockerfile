FROM python:3.14-slim@sha256:a2b82f3c48559aa0a8446d9af49826b6e2b2016f4cd2afabfe6013ec53729170

ARG SOURCE_REVISION=unknown
LABEL org.opencontainers.image.title="iris-mlflow-registry" \
      org.opencontainers.image.source="https://github.com/chiendz11/iris-model-registry" \
      org.opencontainers.image.revision="${SOURCE_REVISION}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get upgrade --yes \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/mlflow
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir --requirement requirements.txt \
    && useradd --create-home --uid 10001 mlflow \
    && chown -R mlflow:mlflow /opt/mlflow
COPY runtime/mlflow-server.sh ./runtime/mlflow-server.sh

USER mlflow
EXPOSE 5000

ENTRYPOINT ["sh", "/opt/mlflow/runtime/mlflow-server.sh"]
