# CI/CD

A self-hosted CI/CD lab assembled from concern-specific Docker Compose files.

## Services

| Service | Started by default | Address |
|---|---:|---|
| Traefik | Yes | HTTPS reverse proxy |
| Gitea | Yes | `https://gitea.app.internal` |
| Registry | Yes | `https://registry.app.internal` |
| Jenkins | No | `https://jenkins.app.internal` |
| SonarQube | No | `https://sonarqube.app.internal` |

Jenkins uses an isolated Docker-in-Docker daemon rather than the host Docker socket.
SonarQube uses a dedicated PostgreSQL database on an internal network.

## Compose structure

Each concern has a Compose file in the repository root:

- `compose.traefik.yaml`
- `compose.gitea.yaml`
- `compose.registry.yaml`
- `compose.jenkins.yaml`
- `compose.sonarqube.yaml`

The Makefile combines them into one Compose project.

## Requirements

- Docker Engine with Docker Compose
- GNU Make
- OpenSSL
- [mkcert](https://github.com/FiloSottile/mkcert)

For SonarQube on Linux, configure the host as required:

```sh
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
```

## Setup

Create the optional ignored runtime override file:

```sh
touch .env
```

The Makefile loads tracked defaults from `.env.local`, applies optional overrides from `.env`, and exports the resulting values to Docker Compose.

Add the service names to `/etc/hosts`. Replace `127.0.0.1` with the Docker
host address when Docker runs on another machine:

```sh
set -a
. ./.env
set +a

cat <<EOF | sudo tee -a /etc/hosts
127.0.0.1 ${GITEA_HOST}
127.0.0.1 ${JENKINS_HOST}
127.0.0.1 ${REGISTRY_HOST}
127.0.0.1 ${SONARQUBE_HOST}
EOF
```

Explicitly prepare the network, generated credentials, and TLS certificate before starting services:

```sh
make setup
```

Start Traefik, Gitea, and the Registry:

```sh
make start
```

Start every service:

```sh
make start.all
```

Start optional services independently:

```sh
make jenkins.start
make sonarqube.start
```

Show all targets and aliases:

```sh
make help
```

## Credentials

Generated credentials and certificates are excluded from Git.

```sh
make jenkins.password
make registry.login
```

Registry credentials and the SonarQube database password are stored in the ignored
`.env` file. The committed `.env.local` file is only the reference configuration.

## Configuration

- Tracked default/reference settings: `.env.local`
- Optional runtime overrides and generated credentials: `.env`
- Jenkins Configuration as Code: `etc/jenkins/jenkins.yaml`
- Traefik static configuration: `etc/traefik/traefik.yaml`
- Traefik TLS configuration: `etc/traefik/dynamic.yaml`

Validate the combined Compose model:

```sh
make validate
```

## Backup and restore

Stop writers or otherwise ensure application consistency before taking a volume archive.

```sh
make backup
make restore BACKUP=backup/YYYYMMDD-HHMMSS
```

The PostgreSQL archive in this lab is a filesystem-level backup. Use `pg_dump` for
an application-consistent SonarQube backup while the database is running.
