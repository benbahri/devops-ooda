FROM jenkins/jenkins:lts-jdk21
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      maven ansible openssh-client curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
# Client Docker seul (binaire officiel : independant de la version de Debian).
# Le daemon est celui de l'hote, atteint via /var/run/docker.sock.
RUN curl -fsSL "https://download.docker.com/linux/static/stable/$(uname -m)/docker-27.3.1.tgz" \
  | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
 && docker --version
# kubectl et kind (architecture detectee)
RUN ARCH=$(dpkg --print-architecture) \
 && curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v1.31.0/bin/linux/${ARCH}/kubectl" \
 && curl -fsSL -o /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-${ARCH}" \
 && chmod +x /usr/local/bin/kubectl /usr/local/bin/kind
USER jenkins
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
COPY init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
# Cle SSH du lab pour joindre la machine cible (Ansible)
RUN mkdir -p /usr/share/jenkins/ref/.ssh \
 && ssh-keygen -t ed25519 -N "" -f /usr/share/jenkins/ref/.ssh/id_lab
COPY settings.xml /usr/share/jenkins/ref/settings.xml
