FROM python:3.15-slim@sha256:94d3426f1def7db4a106a232ac121bfd975393e5dfd40a619b955fae45fe7913

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
