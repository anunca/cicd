#!/usr/bin/env bash
set -euo pipefail

backup_dir="backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "${backup_dir}"

volumes=(
  cicd_gitea-data
  cicd_registry-data
  cicd_jenkins-data
  cicd_sonarqube-db-data
  cicd_sonarqube-data
  cicd_sonarqube-extensions
)

for volume in "${volumes[@]}"; do
  docker run --rm     --volume "${volume}:/source:ro"     --volume "$(pwd)/${backup_dir}:/backup"     alpine:3.22     tar -C /source -czf "/backup/${volume}.tar.gz" .
done

echo "Backup written to ${backup_dir}"
