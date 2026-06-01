COMPOSE := docker compose
PROD_COMPOSE := docker compose -f docker-compose.prod.yml

.PHONY: help setup dev dev-build prod prod-build deploy-prod stop restart status logs logs-backend logs-frontend test test-backend test-frontend build shell-backend shell-frontend db-console clean reset

help:
	@echo "MediTrack commands"
	@echo ""
	@echo "  make setup          Build local development images"
	@echo "  make dev            Start the full app in development mode"
	@echo "  make dev-build      Rebuild images and start the full app"
	@echo "  make prod           Start production compose using configured images"
	@echo "  make prod-build     Build local production images and start production compose"
	@echo "  make deploy-prod    Run the production deployment script"
	@echo "  make stop           Stop and remove containers"
	@echo "  make restart        Restart all services"
	@echo "  make status         Show running services and exposed ports"
	@echo "  make logs           Follow all service logs"
	@echo "  make test           Run backend tests and frontend production build"
	@echo "  make shell-backend  Open a shell in the Rails container"
	@echo "  make shell-frontend Open a shell in the React container"
	@echo "  make clean          Stop containers and remove anonymous build output"
	@echo "  make reset          Stop containers and remove project volumes"

setup:
	$(COMPOSE) build

dev:
	$(COMPOSE) up

dev-build:
	$(COMPOSE) up --build

prod:
	$(PROD_COMPOSE) up -d

prod-build:
	docker build -t meditrack-backend:local ./backend
	docker build -f frontend/Dockerfile.prod --build-arg VITE_API_BASE_URL=http://localhost:3001/api/v1 -t meditrack-frontend:local ./frontend
	$(PROD_COMPOSE) up -d

deploy-prod:
	APP_DIR=$(CURDIR) SKIP_PULL=1 scripts/deploy.sh

stop:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

status:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

logs-backend:
	$(COMPOSE) logs -f backend

logs-frontend:
	$(COMPOSE) logs -f frontend

test: test-backend test-frontend

test-backend:
	$(COMPOSE) exec backend bin/rails test

test-frontend:
	$(COMPOSE) exec frontend npm run build

build:
	$(COMPOSE) build

shell-backend:
	$(COMPOSE) exec backend bash

shell-frontend:
	$(COMPOSE) exec frontend sh

db-console:
	$(COMPOSE) exec backend bin/rails dbconsole

clean:
	$(COMPOSE) down --remove-orphans
	rm -rf frontend/dist

reset:
	$(COMPOSE) down --volumes --remove-orphans
	rm -rf frontend/dist
