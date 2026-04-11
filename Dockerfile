FROM alpine:3.23

ENV USER=borg
ENV UID=1000
ENV GID=1000
ENV MAINTENANCE_ENABLE="false"
ENV INTERACTIVE_MODE="false"
ENV RUN_INSTALL_SCRIPT="false"
ENV RUN_PROMETHEUS_EXPORTER="false"
ENV TZ=""

RUN apk add --no-cache \
  bash sudo openssh-server shadow tzdata curl git dcron coreutils grep sed gawk util-linux ca-certificates tmux fastfetch prometheus-node-exporter \
  borgbackup \
&& mkdir -p \
  /.ssh \
  /backups \
  /logs \
  /run/sshd \
  /root/.cache/crontab \
  /sshkeys/clients \
  /sshkeys/host

VOLUME ["/backups"]
VOLUME ["/logs"]
VOLUME ["/sshkeys/host"]

COPY entrypoint-script/entrypoint.sh /
COPY entrypoint-script/variables.sh /
COPY scripts/borgbackup.sh /usr/local/bin/
COPY prometheus-borg-exporter/borg_exporter.sh /usr/local/bin/
COPY prometheus-borg-exporter/borg_exporter.rc /etc/
COPY bash-config/.bash_profile /root/
COPY bash-config/.bashrc_root /root/
COPY bash-config/.bash_profile /
COPY bash-config/.bashrc /
COPY sshd_config /etc/ssh/sshd_config

RUN chmod 0755 /entrypoint.sh /usr/local/bin/borgbackup.sh /usr/local/bin/borg_exporter.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
