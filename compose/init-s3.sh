#!/usr/bin/env bash
set -euo pipefail

awslocal s3api create-bucket --bucket "${MLFLOW_ARTIFACT_BUCKET:-mlflow}"
awslocal s3api create-bucket --bucket "${DVC_BUCKET:-dvc}"
