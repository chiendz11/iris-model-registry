COMPOSE_ENV ?= config/local.env.example
COMPOSE := docker compose --env-file $(COMPOSE_ENV) --file compose/compose.yaml

.PHONY: up down logs status validate test clean

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f mlflow

status:
	$(COMPOSE) ps

validate:
	$(COMPOSE) config --quiet
	docker build --file runtime/Dockerfile --tag iris-mlflow-registry:local .

test:
	python -m unittest discover -s tests -p 'test_*.py'

clean:
	@echo "This deletes local PostgreSQL and LocalStack volumes. Run: $(COMPOSE) down -v"
