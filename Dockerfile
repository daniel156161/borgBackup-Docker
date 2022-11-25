FROM alpine:edge

ENV USER=borg
ENV UID=1000
ENV GID=1000
ENV MAINTENANCE_ENABLE="false"
ENV INTERACTIVE_MODE="false"
ENV RUN_INSTALL_SCRIPT="false"
ENV RUN_PROMETHEUS_EXPORTER="false"
ENV TZ=""

# Add Folders and Shell Scripts
RUN mkdir "/.ssh"
VOLUME ["/backups"]
VOLUME ["/logs"]
VOLUME ["/sshkeys/host"]

COPY motd.txt /etc/motd
COPY entrypoint-script/entrypoint.sh /
COPY entrypoint-script/variables.sh /
COPY scripts/borgbackup.sh /usr/local/bin/

COPY bash-config/.bash_profile /root/
COPY bash-config/.bashrc /root/

COPY prometheus-borg-exporter/borg_exporter.sh /usr/local/bin/
COPY prometheus-borg-exporter/borg_exporter.rc /etc/

# Install packages
RUN apk update ; apk upgrade
RUN apk add --no-cache sudo bash bash-completion tzdata openssh openrc neofetch \
    borgbackup dateutils prometheus-node-exporter curl
RUN rm -rf /var/cache/apk/*

# Setup SSH-Server
RUN sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
RUN sed -ie 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
RUN sed -ie 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_rsa_key|HostKey /sshkeys/host/ssh_host_rsa_key|g' /etc/ssh/sshd_config
RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_ecdsa_key|HostKey /sshkeys/host/ssh_host_ecdsa_key|g' /etc/ssh/sshd_config
RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_ed25519_key|HostKey /sshkeys/host/ssh_host_ed25519_key|g' /etc/ssh/sshd_config
RUN sed -ie 's|root:x:0:0:root:/root:/bin/ash|root:x:0:0:root:/root:/bin/bash|g' /etc/passwd

EXPOSE 22
ENTRYPOINT [ "/entrypoint.sh" ]
