FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssh-server python3 sudo ca-certificates procps \
    && rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd
RUN useradd -m -s /bin/bash deploy \
 && echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/deploy
# La cle publique est injectee au demarrage depuis le volume partage (voir entrypoint)
COPY entrypoint.sh /entrypoint.sh
# sed : retire les fins de ligne Windows (CRLF) qui provoquent "exec /entrypoint.sh: no such file or directory"
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
EXPOSE 22 8080
ENTRYPOINT ["/entrypoint.sh"]
