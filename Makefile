COMPOSE := docker compose

.PHONY: help dev dev-build prod prod-build stop restart status logs logs-backend logs-frontend test test-backend test-frontend build shell-backend shell-frontend db-console clean reset

help:
	@echo "MediTrack commands"
	@echo ""
	@echo "  make dev            Start the full app in development mode"
	@echo "  make dev-build      Rebuild images and start the full app"
	@echo "  make prod           Build frontend assets, then start containers detached"
	@echo "  make prod-build     Rebuild images, build frontend assets, then start detached"
	@echo "  make stop           Stop and remove containers"
	@echo "  make restart        Restart all services"
	@echo "  make status         Show running services and exposed ports"
	@echo "  make logs           Follow all service logs"
	@echo "  make test           Run backend tests and frontend production build"
	@echo "  make shell-backend  Open a shell in the Rails container"
	@echo "  make shell-frontend Open a shell in the React container"
	@echo "  make clean          Stop containers and remove anonymous build output"
	@echo "  make reset          Stop containers and remove project volumes"

dev:
	$(COMPOSE) up

dev-build:
	$(COMPOSE) up --build

prod:
	$(COMPOSE) up -d
	$(COMPOSE) exec frontend npm run build

prod-build:
	$(COMPOSE) up --build -d
	$(COMPOSE) exec frontend npm run build

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
