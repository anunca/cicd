# Local TLS certificates

Certificates are generated locally and are not committed.

```sh
make certs
```

The target uses `mkcert` to create `tls.crt` and `tls.key` for the configured
domain and its wildcard.
