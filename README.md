# MLflow model registry (repo 2/5)

Repository 2/5 của capstone MLOps. Repo này sở hữu **dịch vụ có trạng thái**:

- MLflow Tracking Server/UI và Model Registry.
- PostgreSQL lưu experiment, run, parameter, metric và model metadata.
- Local: MinIO cung cấp S3-compatible storage cho model artifact và DVC remote.
- AWS deployment của MLflow dùng RDS và S3 do repo `iris-infrastructure` cấp.

Tách repo này khỏi training vì registry có vòng đời, backup, credential và quyền truy cập khác
với source code mô hình. Training job là client có thể thay đổi thường xuyên; registry phải ổn định.

## Chạy local

```bash
cp .env.example .env
# đổi toàn bộ password trong .env
docker compose up -d --build --wait
curl http://localhost:5000/health
```

- MLflow UI: http://localhost:5000
- MinIO API: http://localhost:9000
- MinIO Console: http://localhost:9001

MLflow dùng `--artifacts-destination s3://mlflow`, tức client upload/download artifact qua MLflow
proxy. Vì vậy training/inference client chỉ cần truy cập MLflow; credential S3 được giữ ở server.
DVC là client riêng nên dùng bucket `dvc` và cần credential MinIO qua biến môi trường.

## Dữ liệu bền vững

Hai named volume giữ PostgreSQL và MinIO khi container restart. `docker compose down` không xóa
dữ liệu; `docker compose down -v` có xóa và chỉ nên dùng để reset lab.

## GitOps deployment

Repo `iris-infrastructure` tạo AWS/EKS/IAM và tự mở pull request đồng bộ output không nhạy cảm vào
`iris-gitops`. Repo này chỉ build/push MLflow image rồi tạo pull request cập nhật image SHA; nó
không giữ Terraform và không chạy `kubectl apply`.

MLflow production có hai replica, dùng RDS làm backend store và S3 làm proxied artifact store.
Quyền S3 đến từ IRSA; External Secrets lấy username/password RDS từ Secrets Manager.

## Bảo mật

Giá trị mặc định chỉ phục vụ local demo. Trước khi public/deploy:

1. Local phải đổi password; AWS dùng RDS managed secret, không commit secret.
2. Không public trực tiếp PostgreSQL/MinIO; chỉ expose qua network cần thiết.
3. Bật TLS và authentication cho MLflow khi ra ngoài máy local.
4. Thiết lập backup PostgreSQL và versioning/lifecycle cho object storage.

GitHub repository variables cho CD: `AWS_REGION`, `GITHUB_ACTIONS_ROLE_ARN`,
`MLFLOW_ECR_REPOSITORY`, `GITOPS_REPOSITORY`; secret `GITOPS_TOKEN`.

Runbook hạ tầng nằm trong repo `iris-infrastructure`.
