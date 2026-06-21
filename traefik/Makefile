.PHONY: help
.DEFAULT_GOAL := help

export DOMAIN_NAME=app.internal

help h: ## Show help
	@awk 'BEGIN {FS = ":.*##"} \
	/^[a-zA-Z0-9_. -]+:.*##/ { \
		split($$1,a," "); \
		printf "%-20s %s\n", a[1], $$2 \
	} \
	/^##@/ {printf "\n%s\n", substr($$0,5)}' $(MAKEFILE_LIST)

##@ Cert
mkcert: ## Create
	mkcert -cert-file certs/${DOMAIN_NAME}.crt -key-file certs/${DOMAIN_NAME}.key "${DOMAIN_NAME}" "*.${DOMAIN_NAME}"