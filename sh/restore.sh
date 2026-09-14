#!/usr/bin/env bash
set -euo pipefail

if [[ ${#} -ne 1 ]]; then
  echo "Usage: ${0} backup/YYYYMMDD-HHMMSS" >&2
  exit 1
fi

backup_dir=${1}

for archive in "${backup_dir}"/*.tar.gz; do
  volume=$(basename "${archive}" .tar.gz)
  docker volume create "${volume}" >/dev/null
  docker run --rm     --volume "${volume}:/target"     --volume "$(pwd)/${backup_dir}:/backup:ro"     alpine:3.22     sh -c "rm -rf /target/* && tar -C /target -xzf /backup/$(basename "${archive}")"
done
