.PHONY: up down logs status validate clean

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f mlflow

status:
	docker compose ps

validate:
	docker compose config --quiet
	docker build -t iris-mlflow-registry:local .

clean:
	@echo "This deletes local PostgreSQL and MinIO volumes. Run: docker compose down -v"

