.PHONY: help
.DEFAULT_GOAL := help

include .env
-include .env.local

ENV ?= dev
TAG ?= ${ENV}
DOCKER_SHELL ?= bash

dc = docker compose --env-file .env --env-file .env.local
compose_files = compose.yaml

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
setup se: network secrets.init certs ## Prepare local runtime files

network n: ## Create CI/CD shared network
	@docker network inspect $(CICD_NETWORK) >/dev/null 2>&1 || docker network create $(CICD_NETWORK)

secrets.init si: ## Generate local credentials
	@mkdir -p secrets/jenkins secrets/registry
	@test -f .env.local || { \
		sonar_password=$$(openssl rand -hex 24); \
		registry_password=$$(openssl rand -hex 24); \
		printf 'SONAR_DB_PASSWORD=%s\nREGISTRY_USER=admin\nREGISTRY_PASSWORD=%s\n' \
			"$$sonar_password" "$$registry_password" > .env.local; \
	}
	@test -s secrets/jenkins/admin_password || openssl rand -base64 32 > secrets/jenkins/admin_password
	@test -s secrets/registry/htpasswd || { \
		set -a; . ./.env.local; set +a; \
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
	$(dc) --profile jenkins build

pull p: secrets.init ## Pull images
	$(dc) --profile jenkins --profile quality pull

start s: setup ## Start core services
	$(dc) up -d

start.all sa: setup ## Start all services
	$(dc) --profile jenkins --profile quality up -d

stop st: secrets.init ## Stop containers
	$(dc) --profile jenkins --profile quality down

restart r: stop start ## Restart core services

logs l: secrets.init ## Follow logs
	$(dc) --profile jenkins --profile quality logs -f

ps: secrets.init ## List containers
	$(dc) --profile jenkins --profile quality ps -a

##@ Jenkins
jenkins.start js: setup ## Start Jenkins
	$(dc) --profile jenkins up -d jenkins

jenkins.shell jsh: secrets.init ## Open Jenkins shell
	$(dc) exec jenkins $(DOCKER_SHELL)

jenkins.logs jl: secrets.init ## Follow Jenkins logs
	$(dc) logs -f jenkins

jenkins.password jp: secrets.init ## Show initial Jenkins password
	@cat secrets/jenkins/admin_password

##@ SonarQube
sonarqube.start ss: setup ## Start SonarQube
	$(dc) --profile quality up -d sonarqube

sonarqube.logs sl: secrets.init ## Follow SonarQube logs
	$(dc) logs -f sonarqube

##@ Registry
registry.login rl: secrets.init ## Log in to the Registry
	@set -a; . ./.env.local; set +a; \
		printf '%s' "$$REGISTRY_PASSWORD" | \
		docker login "$(REGISTRY_HOST)" --username "$$REGISTRY_USER" --password-stdin

##@ Maintenance
backup ba: ## Back up persistent volumes
	bash sh/backup.sh

restore re: ## Restore BACKUP=backup/YYYYMMDD-HHMMSS
	@test -n "$(BACKUP)" || { echo "BACKUP is required"; exit 1; }
	bash sh/restore.sh "$(BACKUP)"
