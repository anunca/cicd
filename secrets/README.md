# Local secrets

Runtime secrets are generated locally and are not committed.

```sh
make secrets.init
```

Generated credentials are stored in `.env.local`. The Jenkins password and Registry
`htpasswd` file are mounted as Compose secrets.
