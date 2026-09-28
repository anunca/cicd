.PHONY: help config build start stop restart run shell logs ps clean
.DEFAULT_GOAL := help

include .env.local
-include .env

export

ENV ?= dev
TAG ?= ${ENV}
DOCKER_SHELL ?= bash

dc_files = compose.traefik.yaml compose.gitea.yaml compose.registry.yaml compose.jenkins.yaml compose.sonarqube.yaml
dc = docker compose $(foreach f,$(dc_files),-f $(f))

define export-env
set -a; \
. ./.env.local; \
[ ! -f .env ] || . ./.env; \
set +a;
endef

help h: ## Show help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_. -]+:.*##/ {split($$1,a," "); printf "%-20s %s\n",a[1],$$2}' $(MAKEFILE_LIST)

##@ Setup
secrets.db sdb: ## Generate database passwords
	@grep -q '^GITEA_DB_PASSWORD=' .env || printf 'GITEA_DB_PASSWORD=%s\n' "$$(openssl rand -hex 24)" >> .env
	@grep -q '^SONAR_DB_PASSWORD=' .env || printf 'SONAR_DB_PASSWORD=%s\n' "$$(openssl rand -hex 24)" >> .env

secrets.app sa: ## Generate local credentials (Registry, Jenkins)
	@mkdir -p secrets/registry secrets/jenkins
	@grep -q '^REGISTRY_PASSWORD=' .env || printf 'REGISTRY_PASSWORD=%s\n' "$$(openssl rand -hex 24)" >> .env
	@test -s secrets/jenkins/admin_password || openssl rand -base64 32 > secrets/jenkins/admin_password
	@test -s secrets/registry/htpasswd || { \
		$(export-env) \
		docker run --rm --entrypoint htpasswd httpd:2.4-alpine \
			-Bbn "$$REGISTRY_USER" "$$REGISTRY_PASSWORD" > secrets/registry/htpasswd; \
	}

network n: ## Create CI/CD shared network
	@docker network inspect $(CICD_NETWORK) >/dev/null 2>&1 || docker network create $(CICD_NETWORK)

certs ce: ## Generate local TLS certificate
	@mkdir -p certs
	@test -s certs/tls.crt -a -s certs/tls.key || \
		mkcert -cert-file certs/tls.crt \
			-key-file certs/tls.key \
			"$(DOMAIN_NAME)" "*.$(DOMAIN_NAME)"

##@ Docker
config c: ## Show configuration
	$(dc) config

validate v: ## Validate configuration
	$(dc) config --quiet

build b: ## Build images
	$(dc) build

start s: ## Start core services
	$(dc) up -d traefik gitea registry

start.all sall: ## Start all services
	$(dc) up -d

stop st: ## Stop containers
	$(dc) down -t0

restart r: stop start ## Restart core services

run: ## Run shell
	$(dc) run --rm --entrypoint $(DOCKER_SHELL) jenkins

shell sh: ## Exec shell
	$(dc) exec jenkins $(DOCKER_SHELL)

logs l: ## Follow logs
	$(dc) logs -f

ps: ## List containers
	$(dc) ps -a

clean: ## Remove containers and volumes
	$(dc) down -t0 --volumes --remove-orphans

##@ Jenkins
jenkins.start js: ## Start Jenkins
	$(dc) up -d jenkins

jenkins.shell jsh: ## Open Jenkins shell
	$(dc) exec jenkins $(DOCKER_SHELL)

jenkins.logs jl: ## Follow Jenkins logs
	$(dc) logs -f jenkins

jenkins.password jp: ## Show initial Jenkins password
	@cat secrets/jenkins/admin_password

##@ SonarQube
sonarqube.start ss: ## Start SonarQube
	$(dc) up -d sonarqube

sonarqube.logs sl: ## Follow SonarQube logs
	$(dc) logs -f sonarqube

##@ Registry
registry.login rl: ## Log in to the Registry
	@$(export-env) \
		printf '%s' "$$REGISTRY_PASSWORD" | \
		docker login "$(REGISTRY_HOST)" --username "$$REGISTRY_USER" --password-stdin

##@ Maintenance
backup ba: ## Back up persistent volumes
	@$(export-env) \
		bash sh/backup.sh

restore re: ## Restore BACKUP=backup/YYYYMMDD-HHMMSS
	@test -n "$(BACKUP)" || { echo "BACKUP is required"; exit 1; }
	bash sh/restore.sh "$(BACKUP)"
