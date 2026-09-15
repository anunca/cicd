.PHONY: help
.DEFAULT_GOAL := help

include .env.local
-include .env

ENV ?= dev
TAG ?= ${ENV}
DOCKER_SHELL ?= bash

dc_files = compose.traefik.yaml compose.gitea.yaml compose.registry.yaml compose.jenkins.yaml compose.sonarqube.yaml
dc = docker compose $(foreach f,$(dc_files),-f $(f))

export ENV
export TAG

help h: ## Show help
	@awk 'BEGIN {FS = ":.*##"} \
	/^[a-zA-Z0-9_. -]+:.*##/ { \
		split($$1,a," "); \
		printf "%-20s %s\n", a[1], $$2 \
	} \
	/^##@/ {printf "\n%s\n", substr($$0,5)}' $(MAKEFILE_LIST)

##@ Setup
env e: ## Create runtime environment file
	@test -f .env || cp .env.local .env

setup se: network secrets.init certs ## Prepare local runtime files

network n: ## Create CI/CD shared network
	@docker network inspect $(CICD_NETWORK) >/dev/null 2>&1 || docker network create $(CICD_NETWORK)

secrets.init si: env ## Generate local credentials
	@mkdir -p secrets/jenkins secrets/registry
	@grep -q '^SONAR_DB_PASSWORD=' .env || printf 'SONAR_DB_PASSWORD=%s\n' "$$(openssl rand -hex 24)" >> .env
	@grep -q '^REGISTRY_USER=' .env || printf 'REGISTRY_USER=admin\n' >> .env
	@grep -q '^REGISTRY_PASSWORD=' .env || printf 'REGISTRY_PASSWORD=%s\n' "$$(openssl rand -hex 24)" >> .env
	@test -s secrets/jenkins/admin_password || openssl rand -base64 32 > secrets/jenkins/admin_password
	@test -s secrets/registry/htpasswd || { \
		set -a; . ./.env; set +a; \
		docker run --rm --entrypoint htpasswd httpd:2.4-alpine \
			-Bbn "$$REGISTRY_USER" "$$REGISTRY_PASSWORD" > secrets/registry/htpasswd; \
	}

certs ce: ## Generate local TLS certificate
	@mkdir -p certs
	@test -s certs/tls.crt -a -s certs/tls.key || \
		mkcert -cert-file certs/tls.crt \
			-key-file certs/tls.key \
			"$(DOMAIN_NAME)" "*.$(DOMAIN_NAME)"

##@ Docker
config c: secrets.init ## Show configuration
	$(dc) config

validate v: secrets.init ## Validate configuration
	$(dc) config --quiet

build b: secrets.init ## Build images
	$(dc) build

pull p: secrets.init ## Pull images
	$(dc) pull

start s: setup ## Start core services
	$(dc) up -d traefik gitea registry

start.all sa: setup ## Start all services
	$(dc) up -d

stop st: secrets.init ## Stop containers
	$(dc) down

restart r: stop start ## Restart core services

logs l: secrets.init ## Follow logs
	$(dc) logs -f

ps: secrets.init ## List containers
	$(dc) ps -a

##@ Jenkins
jenkins.start js: setup ## Start Jenkins
	$(dc) up -d jenkins

jenkins.shell jsh: secrets.init ## Open Jenkins shell
	$(dc) exec jenkins $(DOCKER_SHELL)

jenkins.logs jl: secrets.init ## Follow Jenkins logs
	$(dc) logs -f jenkins

jenkins.password jp: secrets.init ## Show initial Jenkins password
	@cat secrets/jenkins/admin_password

##@ SonarQube
sonarqube.start ss: setup ## Start SonarQube
	$(dc) up -d sonarqube

sonarqube.logs sl: secrets.init ## Follow SonarQube logs
	$(dc) logs -f sonarqube

##@ Registry
registry.login rl: secrets.init ## Log in to the Registry
	@set -a; . ./.env; set +a; \
		printf '%s' "$$REGISTRY_PASSWORD" | \
		docker login "$(REGISTRY_HOST)" --username "$$REGISTRY_USER" --password-stdin

##@ Maintenance
backup ba: env ## Back up persistent volumes
	bash sh/backup.sh

restore re: ## Restore BACKUP=backup/YYYYMMDD-HHMMSS
	@test -n "$(BACKUP)" || { echo "BACKUP is required"; exit 1; }
	bash sh/restore.sh "$(BACKUP)"
