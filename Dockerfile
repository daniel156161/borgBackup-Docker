FROM archlinux:latest

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

COPY entrypoint-script/entrypoint.sh /
COPY entrypoint-script/variables.sh /
COPY scripts/borgbackup.sh /usr/local/bin/

COPY bash-config/.bash_profile /root/
COPY bash-config/.bashrc_root /root/

COPY bash-config/.bash_profile /
COPY bash-config/.bashrc /
COPY bash-config/locale.gen /etc/locale.gen

COPY prometheus-borg-exporter/borg_exporter.sh /usr/local/bin/
COPY prometheus-borg-exporter/borg_exporter.rc /etc/

# Create .cache folder
RUN mkdir -p "/root/.cache/crontab"

# Create locale files
RUN locale-gen

# Install packages
RUN pacman-key --init
RUN pacman -Syu --noconfirm sudo bash-completion openssh neofetch \
    borgbackup dateutils prometheus-node-exporter wget git base-devel cron net-tools inetutils tmux

# Make Build User
RUN useradd builduser -m
RUN passwd -d builduser
RUN printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers
RUN sudo -u builduser bash -c 'cd ~ && git clone https://aur.archlinux.org/teleport-bin.git teleport && cd teleport && makepkg -si --noconfirm && cd ~ && rm -rf teleport'
RUN userdel -r builduser

# Setup SSH-Server
RUN sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
RUN sed -ie 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
RUN sed -ie 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_rsa_key|HostKey /sshkeys/host/ssh_host_rsa_key|g' /etc/ssh/sshd_config
RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_ecdsa_key|HostKey /sshkeys/host/ssh_host_ecdsa_key|g' /etc/ssh/sshd_config
RUN sed -ie 's|#HostKey /etc/ssh/ssh_host_ed25519_key|HostKey /sshkeys/host/ssh_host_ed25519_key|g' /etc/ssh/sshd_config

EXPOSE 22
ENTRYPOINT [ "/entrypoint.sh" ]
