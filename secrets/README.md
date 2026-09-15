# Local secrets

Runtime secrets are generated locally and are not committed.

```sh
cp .env.local .env
make secrets.init
```

Registry credentials and the SonarQube database password are stored in the ignored
`.env` file. The Jenkins password and Registry `htpasswd` file are mounted as
Compose secrets.
