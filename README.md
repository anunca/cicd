# CI/CD

A self-hosted CI/CD lab managed by one Docker Compose project.

## Services

| Service | Default | Address |
|---|---:|---|
| Traefik | Yes | HTTPS reverse proxy |
| Gitea | Yes | `https://gitea.app.internal` |
| Registry | Yes | `https://registry.app.internal` |
| Jenkins | Optional | `https://jenkins.app.internal` |
| SonarQube | Optional | `https://sonarqube.app.internal` |

Jenkins uses an isolated Docker-in-Docker daemon rather than the host Docker socket.
SonarQube uses a dedicated PostgreSQL database on an internal network.

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

Add the service names to local DNS or `/etc/hosts`, pointing them to the Docker host:

```text
127.0.0.1 gitea.app.internal
127.0.0.1 jenkins.app.internal
127.0.0.1 registry.app.internal
127.0.0.1 sonarqube.app.internal
```

Prepare the network, local credentials, and TLS certificate:

```sh
make setup
```

Start the core platform:

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

Show all available targets and aliases:

```sh
make help
```

## Credentials

Generated credentials and certificates are excluded from Git.

```sh
make jenkins.password
make registry.login
```

Registry credentials and the SonarQube database password are stored in the local
`.env.local` file.

## Configuration

- Runtime settings: `.env`
- Private local settings: `.env.local`
- Jenkins Configuration as Code: `etc/jenkins/jenkins.yaml`
- Traefik static configuration: `etc/traefik/traefik.yaml`
- Traefik TLS configuration: `etc/traefik/dynamic.yaml`

Validate the rendered Compose model:

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
application-consistent SonarQube backups while the database is running.
