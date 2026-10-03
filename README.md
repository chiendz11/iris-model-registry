# MLflow model registry (repo 2/5)

Repo này là source of truth cho **MLflow server runtime image và local development stack**. Nó
không sở hữu RDS, S3, IAM, Kubernetes manifests hay production rollout.

## Ownership

```text
iris-model-registry
├── runtime/             pinned MLflow container and secure entrypoint
├── config/              documented runtime interface and local example values
├── contracts/           versioned non-secret runtime-config schema
├── release/             reviewed production config and secret references
├── compose/             PostgreSQL + LocalStack S3 + MLflow for local/CI only
├── tests/               health and repository-boundary checks
├── requirements.txt     pinned runtime dependencies
└── .github/workflows/   test, build, scan, publish and release intent
```

RDS/S3/IAM do `iris-infrastructure` tạo. Deployment, Service, PDB, ExternalSecret và production
runtime values nằm trong `iris-gitops`. Repo này không có `terraform/` hoặc
`environments/production/`.

## Chạy local

```bash
cp config/local.env.example .env
# đổi password trong .env
COMPOSE_ENV=.env make up
curl http://localhost:5000/health
```

- MLflow UI: <http://localhost:5000>
- LocalStack S3 gateway: <http://localhost:4566>

MLflow dùng proxied artifact storage (`--artifacts-destination s3://mlflow`), nên training và
inference client chỉ nói chuyện với MLflow. DVC là client riêng dùng bucket local `dvc`.

`make down` giữ named volumes; chỉ `docker compose ... down -v` mới xóa dữ liệu lab. Mặc định
Makefile dùng `config/local.env.example`; hãy dùng `COMPOSE_ENV=.env` khi đã tạo file riêng.

## Runtime contract và bảo mật

`runtime/mlflow-server.sh` fail closed nếu thiếu backend/artifact configuration. Allowed Host và
CORS origin phải được cấu hình rõ; runtime không còn hard-code wildcard `*`. Local Compose đặt các
giá trị localhost, còn GitOps production cung cấp hostname thực tế. Interface không nhạy cảm được
mô tả ở `config/server.env.example`; RDS password không được commit mà đến từ AWS Secrets Manager
qua External Secrets.

Production dùng RDS Multi-AZ làm backend store và S3 làm artifact store, nhưng implementation của
hai resource đó không thuộc repo này. MLflow chạy internal; nếu public UI thì lớp ingress phải thêm
TLS và authentication tại GitOps/platform boundary.

## Workload release không biết GitOps layout

Sau merge vào `main`, CI thực hiện:

```text
Compose health test
        ↓
build image từ pinned base
        ↓
Trivy critical-vulnerability gate
        ↓
OIDC push SHA tag vào ECR
        ↓
resolve image digest
        ↓
Cosign keyless sign repository@digest
        ↓
workflow_dispatch workload-release.yml với workload-release/v1 contract
```

Nếu chỉ runtime/Dockerfile/dependency đổi, CI gửi image digest cùng schema compatibility metadata.
Nếu chỉ schema hoặc `release/production-runtime-config.json` đổi, CI gửi config-only intent; chỉ đổi
`release/production-secret-refs.json` thì gửi secret-ref-only intent. Không trường hợp nào trong hai
nhánh này publish image mới. Khi image yêu cầu config mới, app PR đổi cả code và schema/value nên CI
phát một workload intent atomic chứa cả hai. Tests/docs không tạo production release.

`release/config-schema-version.txt` chọn schema active trong `contracts/` (hiện là `v1`). Schema v1
bắt buộc explicit allowed hosts/CORS và giới hạn số worker. CI validate values trước khi gửi;
GitOps so khớp version + SHA-256 với schema đã được phê duyệt. Image-only cũng bị validate với
config hiện hành nên không thể bỏ qua required key. Secret file chỉ chứa AWS Secrets Manager
reference, không chứa credential. RDS username/password vẫn là platform-owned `ExternalSecret`,
không đi qua workload intent.
Khi nâng schema, thêm `runtime-config-vN.schema.json` mới và bản được review tương ứng ở GitOps,
sau đó mới đổi con trỏ; không mutate contract version cũ đã phát hành.

Intent mang `component=model-registry`, artifact/config, source repo/SHA và change ID. CI không
checkout `iris-gitops`, không sửa `kustomization.yaml` và không tự tạo deployment PR. Renderer trong
`iris-gitops` mới biết desired-state layout, enforce ECR allow-list, verify chữ ký Cosign từ đúng
workflow `iris-model-registry/.github/workflows/ci.yml@main` và mở protected PR.

GitHub Environment `prod` cần variables:

- `AWS_REGION`, `AWS_DEPLOY_ROLE_ARN`, `MLFLOW_ECR_REPOSITORY`;
- `GITOPS_REPOSITORY` (dạng `owner/iris-gitops`);
- `INTENT_PUBLISHER_APP_CLIENT_ID`.

Secret `INTENT_PUBLISHER_APP_PRIVATE_KEY` là key riêng của App
`iris-model-registry-publisher` và tạo token ngắn hạn chỉ có `Actions: write` trên
`iris-gitops`. App CI không nhận `Contents: write`, không có Pull Requests permission và không giữ
PAT dài hạn.
