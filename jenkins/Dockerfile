ARG JENKINS_VERSION
FROM $JENKINS_VERSION

USER root

# RUN apk add --no-cache docker\
#   && addgroup jenkins docker
# RUN curl -sSL https://get.docker.com/ | sh
COPY --from=docker:20.10.5 /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker/compose:alpine-1.28.5 /usr/local/bin/docker-compose /usr/local/bin/docker-compose

#kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl\
  && chmod +x ./kubectl\
  && mv ./kubectl /usr/local/bin/kubectl

#jenkins
COPY etc/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

ARG JAVA_OPTS
# ARG JENKINS_USER
# ARG JENKINS_PASS

ENV JAVA_OPTS ${JAVA_OPTS}
# ENV JENKINS_USER ${JENKINS_USER}
# ENV JENKINS_PASS ${JENKINS_PASS}

# COPY etc/default-user.groovy /usr/share/jenkins/ref/init.groovy.d/
# COPY etc/executors.groovy /usr/share/jenkins/ref/init.groovy.d/

COPY etc/jenkins-casc.yaml /usr/local/jenkins-casc.yaml
ENV CASC_JENKINS_CONFIG /usr/local/jenkins-casc.yaml

USER jenkins
