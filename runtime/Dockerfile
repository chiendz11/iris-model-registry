FROM python:3.12-slim@sha256:dddfd7e07f9d15aeeca61529320492139d21cac7f0070c00609243e51e4e0016

ARG SOURCE_REVISION=unknown
LABEL org.opencontainers.image.title="iris-mlflow-registry" \
      org.opencontainers.image.source="https://github.com/chiendz11/iris-model-registry" \
      org.opencontainers.image.revision="${SOURCE_REVISION}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/mlflow
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir --requirement requirements.txt \
    && useradd --create-home --uid 10001 mlflow \
    && chown -R mlflow:mlflow /opt/mlflow
COPY runtime/mlflow-server.sh ./runtime/mlflow-server.sh

USER mlflow
EXPOSE 5000

ENTRYPOINT ["sh", "/opt/mlflow/runtime/mlflow-server.sh"]
