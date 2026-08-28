.PHONY: help
.DEFAULT_GOAL := help

help h: ## Show help
	@awk 'BEGIN {FS = ":.*##"} \
	/^[a-zA-Z0-9_. -]+:.*##/ { \
		split($$1,a," "); \
		printf "%-20s %s\n", a[1], $$2 \
	} \
	/^##@/ {printf "\n%s\n", substr($$0,5)}' $(MAKEFILE_LIST)

SERVICES = gitea jenkins registry sonarqube traefik

dc = docker compose

define dc_cmd
$(dc) -f $1/docker-compose.yml --env-file $1/.env
endef

##@ Docker
config c: ## Show config
	@for s in $(SERVICES); do \
		$(call dc_cmd,$$s) config; \
	done

build b: ## Build images
	@for s in $(SERVICES); do \
		$(call dc_cmd,$$s) build; \
	done

start s: ## Start containers
	@for s in $(SERVICES); do \
		if [[ "$$s" != "gitlab" ]]; then \
			$(call dc_cmd,$$s) up -d; \
		fi \
	done

stop st: ## Stop containers
	@for s in $(SERVICES); do \
		$(call dc_cmd,$$s) down --remove-orphans; \
	done

restart r: stop start ## Restart
	@for s in $(SERVICES); do \
		$(call dc_cmd,$$s) restart; \
	done

logs l: ## Follow logs
	@for s in $(SERVICES); do \
		$(call dc_cmd,$$s) logs -f; \
	done

ps: ## List containers
	@for s in $(SERVICES); do \
		$(call dc_cmd,$$s) ps; \
	done

network.create: ## Network create
	@docker network ls | grep -q cicd || docker network create cicd	