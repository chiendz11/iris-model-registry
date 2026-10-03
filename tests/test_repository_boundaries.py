import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RepositoryBoundaryTest(unittest.TestCase):
    def test_release_emits_generic_intent_without_rendering_gitops(self) -> None:
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")

        self.assertIn("actions/workflows/workload-release.yml/dispatches", workflow)
        self.assertIn("runtime_config", workflow)
        self.assertIn("config_schema_digest", workflow)
        self.assertIn("contract_version", workflow)
        self.assertIn("--arg component model-registry", workflow)
        self.assertIn("permission-actions: write", workflow)
        self.assertIn("cosign sign", workflow)

        forbidden = (
            "environments/production",
            "gh pr create",
            "git checkout -b",
            "sed -i",
            "permission-contents: write",
            "permission-pull-requests: write",
        )
        for value in forbidden:
            self.assertNotIn(value, workflow)

    def test_repository_contains_no_production_deployment_manifests(self) -> None:
        self.assertFalse((ROOT / "environments").exists())
        self.assertFalse((ROOT / "terraform").exists())

    def test_production_mlflow_hosts_cover_kubernetes_tracking_uri_port(self) -> None:
        config = json.loads(
            (ROOT / "release/production-runtime-config.json").read_text(
                encoding="utf-8"
            )
        )
        allowed_hosts = set(config["MLFLOW_ALLOWED_HOSTS"].split(","))
        kubernetes_hosts = {
            "mlflow",
            "mlflow.mlops.svc",
            "mlflow.mlops.svc.cluster.local",
        }

        self.assertNotIn("*", allowed_hosts)
        for host in kubernetes_hosts:
            self.assertIn(host, allowed_hosts)
            self.assertIn(f"{host}:5000", allowed_hosts)


if __name__ == "__main__":
    unittest.main()
