.PHONY: help
.DEFAULT_GOAL := help

include .env.local
-include .env

DOCKER_SHELL ?= bash

dc_files = compose.traefik.yaml compose.gitea.yaml compose.registry.yaml compose.jenkins.yaml compose.sonarqube.yaml
dc = docker compose $(foreach f,$(dc_files),-f $(f))

export COMPOSE_PROJECT_NAME
export CICD_NETWORK
export TRAEFIK_VERSION
export GITEA_VERSION
export JENKINS_VERSION
export DOCKER_VERSION
export KUBECTL_VERSION
export REGISTRY_VERSION
export SONARQUBE_VERSION
export POSTGRES_VERSION
export GITEA_HOST
export JENKINS_HOST
export REGISTRY_HOST
export SONARQUBE_HOST
export GITEA_DB_NAME
export GITEA_DB_USER
export GITEA_DB_PASSWORD
export JENKINS_ADMIN_ID
export SONAR_DB_NAME
export SONAR_DB_USER
export SONAR_DB_PASSWORD

define export-env
set -a; \
. ./.env.local; \
[ ! -f .env ] || . ./.env; \
set +a;
endef

help h: ## Show help
	@awk 'BEGIN {FS = ":.*##"} \
	/^[a-zA-Z0-9_. -]+:.*##/ { \
		split($$1,a," "); \
		printf "%-20s %s\n", a[1], $$2 \
	} \
	/^##@/ {printf "\n%s\n", substr($$0,5)}' $(MAKEFILE_LIST)

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

pull p: ## Pull images
	$(dc) pull

start s: ## Start core services
	$(dc) up -d traefik gitea registry

start.all sall: ## Start all services
	$(dc) up -d

stop st: ## Stop containers
	$(dc) down

restart r: stop start ## Restart core services

logs l: ## Follow logs
	$(dc) logs -f

ps: ## List containers
	$(dc) ps -a

clean: ## Remove containers and this lab's volumes
	$(dc) down --volumes --remove-orphans

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
