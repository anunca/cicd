#!/usr/bin/env bash
set -euo pipefail

set -a
. ./.env
set +a

backup_dir="backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "${backup_dir}"

project=${COMPOSE_PROJECT_NAME:-cicd}
volumes=(
"${project}_gitea-data"
"${project}_registry-data"
"${project}_jenkins-data"
"${project}_sonarqube-db-data"
"${project}_sonarqube-data"
"${project}_sonarqube-extensions"
)

for volume in "${volumes[@]}"; do
docker run --rm \
--volume "${volume}:/source:ro" \
--volume "$(pwd)/${backup_dir}:/backup" \
alpine:3.22 \
tar -C /source -czf "/backup/${volume}.tar.gz" .
done

echo "Backup written to ${backup_dir}"
