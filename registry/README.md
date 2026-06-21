# registry
## overview
- [doc](#doc)
- [install](#install)
- [notes](#notes)
## doc
- https://docs.docker.com/reference/api/registry/auth/
- https://hub.docker.com/_/registry
## install
```sh
```
## notes
```sh
DOMAIN_NAME=app.internal
SUB_DOMAIN_NAME=registry.$DOMAIN_NAME
```
enable https registry with self signed crt
```sh
rm -rf /etc/docker/certs.d/*\
&& mkdir -p /etc/docker/certs.d/$DOMAIN_NAME:443\
&& cp ../traefik/certs/$DOMAIN_NAME.crt /etc/docker/certs.d/$DOMAIN_NAME:443/ca.crt\
```
```sh
&& rm -rf /usr/local/share/ca-certificates/*\
&& cp -f ../traefik/certs/$DOMAIN_NAME.crt /usr/local/share/ca-certificates/$DOMAIN_NAME.crt\
```
```sh
update-ca-certificates\
&& systemctl restart docker.service
```
test registry
```sh
docker pull hello-world
```
```sh
docker tag hello-world $SUB_DOMAIN_NAME/hello-world
```
```sh
docker push $SUB_DOMAIN_NAME/hello-world
```
check http registry
```sh
curl http://$SUB_DOMAIN_NAME/v2/_catalog
```
https registry
```sh
curl -k https://root:root@$SUB_DOMAIN_NAME/v2/_catalog
```