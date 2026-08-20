# Kubernetes deployment note

`compose.yaml` là đường chạy local và CI smoke test. Với Kubernetes, không nên bê nguyên
PostgreSQL/MinIO single-node này vào production. Dùng managed PostgreSQL và S3 hoặc chart có
backup/HA, sau đó tạo Secret theo hướng dẫn chính thức của MLflow Helm deployment.

Namespace mẫu được cung cấp để giữ ranh giới network/RBAC. Credential không được commit vào repo.

