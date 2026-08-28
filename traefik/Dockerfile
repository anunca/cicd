ARG TRAEFIK_VERSION=traefik:v3.7.12
FROM $TRAEFIK_VERSION

ARG DOMAIN_NAME

COPY /etc/traefik.yml /etc/traefik/traefik.yml

COPY /etc/config.tmp /etc/traefik/config.yml
RUN sed -i "s/###DOMAIN_NAME###/${DOMAIN_NAME}/g" /etc/traefik/config.yml

COPY /certs/${DOMAIN_NAME}.crt /etc/certs/${DOMAIN_NAME}.pem
COPY /certs/${DOMAIN_NAME}.key /etc/certs/${DOMAIN_NAME}.pem
