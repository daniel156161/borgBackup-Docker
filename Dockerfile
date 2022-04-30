FROM alpine:edge

ENV USER=borg
ENV UID=1000
ENV GID=1000

# Add Folders and Shell Scripts
RUN mkdir "/.ssh"
VOLUME ["/backups"]
COPY motd.txt /etc/motd
COPY entrypoint.sh /

# Install packages
RUN apk update ; apk upgrade
RUN apk add --no-cache sudo bash tzdata openssh-server openrc \
    borgbackup
RUN rm -rf /var/cache/apk/*

# Setup SSH-Server
RUN sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
RUN sed -ie 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
RUN sed -ie 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_rsa_key|HostKey /sshkeys/host/ssh_host_rsa_key|g' /etc/ssh/sshd_config
RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_ecdsa_key|HostKey /sshkeys/host/ssh_host_ecdsa_key|g' /etc/ssh/sshd_config
RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_ed25519_key|HostKey /sshkeys/host/ssh_host_ed25519_key|g' /etc/ssh/sshd_config

EXPOSE 22
ENTRYPOINT [ "/entrypoint.sh" ]
