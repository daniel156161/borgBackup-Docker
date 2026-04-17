#!/bin/bash
set -euo pipefail

source "/variables.sh"
USER_GROUP="$USER"
###############################################################################
# Funktionen
###############################################################################
function set_environment_variables_if_not_empty {
  # Set Tmux Shell for .bashrc to load tmux and attach session if exists else create new session
  if [ -n "${USE_TMUX_SHELL:-}" ]; then
    grep -q "^USE_TMUX_SHELL=" /etc/environment || echo "USE_TMUX_SHELL=$USE_TMUX_SHELL" >> /etc/environment
  fi

  # Set Server Timezone
  if [ -n "${TZ:-}" ]; then
    grep -q "^TZ=" /etc/environment || echo "TZ=$TZ" >> /etc/environment
    ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
  fi
}

function print_container_info {
  sepurator
  echo "* BorgServer powered by $BORG_VERSION"
  echo "* Image Hostname: $HOSTNAME"
  echo "* Image Version: $DOCKER_IMAGE_VERSION"
}

function print_user_info {
  sepurator
  echo "* USER:  $USER - ID:  $UID"
  echo "* GROUP: $USER - GID: $GID"
}

function create_folder_and_change_permissions {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
  chown -R "$USER":"$USER_GROUP" "$1"
}

function add_borg_user {
  if ! id "$USER" >/dev/null 2>&1; then
    local group_name="$USER"
    local existing_group
    existing_group="$(getent group "$GID" | cut -d: -f1 || true)"
    if [ -n "$existing_group" ]; then
      group_name="$existing_group"
    elif ! getent group "$USER" >/dev/null 2>&1; then
      groupadd -g "$GID" "$USER" >/dev/null
    fi
    USER_GROUP="$group_name"

    if getent passwd "$UID" >/dev/null 2>&1; then
      existing_user="$(getent passwd "$UID" | cut -d: -f1)"
      usermod -l "$USER" "$existing_user" >/dev/null 2>&1 || true
      usermod -d / -s /bin/bash -g "$group_name" "$USER" >/dev/null
    else
      useradd -M -u "$UID" -g "$group_name" -d / -s /bin/bash "$USER" >/dev/null
    fi
    printf "%s ALL=(ALL) NOPASSWD: ALL\n" "$USER" >> /etc/sudoers

    create_folder_and_change_permissions "/.config"
    create_folder_and_change_permissions "/.cache"
    chmod 700 "/.cache"
  else
    USER_GROUP="$(id -gn "$USER")"
  fi

  random_pw="$(dd if=/dev/urandom bs=18 count=1 2>/dev/null | base64)"
  echo "${USER}:${random_pw}" | chpasswd >/dev/null 2>&1 || true
}

function add_docker_socket_permission {
  if [ ! -S /var/run/docker.sock ]; then
    return
  fi

  local sock_gid
  sock_gid="$(stat -c '%g' /var/run/docker.sock)"
  local group_name
  group_name="$(getent group "$sock_gid" | cut -d: -f1 || true)"

  if [ -z "$group_name" ]; then
    groupadd -g "$sock_gid" docker
    group_name="docker"
  fi

  usermod -aG "$group_name" "$USER"
  echo "* Docker socket access granted ($group_name GID=$sock_gid)"

  local server_api
  server_api="$(curl -sf --unix-socket /var/run/docker.sock http://localhost/version 2>/dev/null \
    | grep -o '"ApiVersion":"[^"]*"' | head -1 | cut -d'"' -f4 | tr -d '[:space:]' || true)"
  if [ -n "$server_api" ]; then
    printf 'export DOCKER_API_VERSION="%s"\n' "$server_api" > /etc/profile.d/docker_api_version.sh
    printf 'DOCKER_API_VERSION=%s\n' "$server_api" > "/.ssh/environment"
    sed -i '/^DOCKER_API_VERSION=/d' /etc/environment
    printf 'DOCKER_API_VERSION=%s\n' "$server_api" >> /etc/environment
    export DOCKER_API_VERSION="$server_api"
    echo "* Docker API version pinned to $server_api"
  fi
}

function make_and_import_ssh_keys {
  local create_folders="0"

  mkdir -p "/.ssh"
  : > "/.ssh/authorized_keys"

  for key_dir in "${SSH_FOLDERS[@]}"; do
    if [ ! -d "$key_dir" ]; then
      mkdir -p "$key_dir"
      echo "Created $key_dir"
      create_folders="1"
    fi
  done

  if [ "$create_folders" = "1" ]; then
    sepurator
  fi

  echo "* IMPORT SSH KEYS"

  shopt -s nullglob
  for key in /sshkeys/clients/*; do
    echo "-  Adding SSH-Key $(basename "$key")"
    awk 'NF' "$key" >> "/.ssh/authorized_keys"
    printf '\n' >> "/.ssh/authorized_keys"
  done
  shopt -u nullglob

  chown -R "$USER":"$USER_GROUP" "/.ssh"
  chmod 700 "/.ssh"
  chmod 600 "/.ssh/authorized_keys"
}

function print_message {
  echo ""
  echo "- $1"
  echo ""
}

function generate_host_sshkey {
  # Generate SSH-Keys
  mkdir -p /sshkeys/host

  if [ ! -f "/sshkeys/host/ssh_host_rsa_key" ]; then
    sepurator
    print_message "HOST SSH-KEY RSA not found, generating..."
    ssh-keygen -q -t rsa -b 4096 -f "/sshkeys/host/ssh_host_rsa_key" -N ""
    print_message "HOST SSH-KEY RSA Generated"
  fi
  if [ ! -f "/sshkeys/host/ssh_host_ecdsa_key" ]; then
    sepurator
    print_message "HOST SSH-KEY ECDSA not found, generating..."
    ssh-keygen -q -t ecdsa -b 521 -f "/sshkeys/host/ssh_host_ecdsa_key" -N ""
    print_message "HOST SSH-KEY ECDSA Generated"
  fi
  if [ ! -f "/sshkeys/host/ssh_host_ed25519_key" ]; then
    sepurator
    print_message "HOST SSH-KEY ED25519 not found, generating..."
    ssh-keygen -q -t ed25519 -f "/sshkeys/host/ssh_host_ed25519_key" -N ""
    print_message "HOST SSH-KEY ED25519 Generated"
  fi

  chmod 600 /sshkeys/host/ssh_host_*_key
  chmod 644 /sshkeys/host/ssh_host_*_key.pub
  chown root:root /sshkeys/host/ssh_host_* || true
}

function maintenance_enable {
  if [ "$MAINTENANCE_ENABLE" != "false" ]; then
    echo "* MAINTENANCE MODE - ENABLED"
    if [ -f "/crontab.txt" ]; then
      crontab "/crontab.txt"
      crond
      echo "- Crontab loaded successfully"
    else
      echo "- Can not find /crontab.txt"
    fi
    sepurator
  fi
}

function show_timezone_output {
  if [ -n "${TZ:-}" ]; then
    echo "* Setting Timezone to $TZ"
  else
    echo "* Timezone not set - Use UTC Time"
  fi
  sepurator
}

function run_install_script {
  if [ "$RUN_INSTALL_SCRIPT" != "false" ] && [ ! -f "/.runnedInstall" ]; then
    echo "* RUNNING INSTALL SCRIPT"
    sepurator
    sh "$RUN_INSTALL_SCRIPT"
    sepurator
    touch "/.runnedInstall"
  fi
}

function run_prometheus_exporter {
  if [ "$RUN_PROMETHEUS_EXPORTER" != "false" ]; then
    create_folder_and_change_permissions "/var/log/"

    echo "* STARTING Prometheus Exporter for Borg Backup"

    crontab -l > /tmp/cron_bkp 2>/dev/null || true
    echo "" >> /tmp/cron_bkp
    echo "- Add Cronjob to Crontab"
    echo "$RUN_PROMETHEUS_EXPORTER su -c '/usr/local/bin/borg_exporter.sh 2>&1' -s /bin/bash borg" >> /tmp/cron_bkp
    crontab /tmp/cron_bkp >/dev/null 2>&1
    rm /tmp/cron_bkp

    if [ ! -f "/var/log/borg_exporter.prom" ]; then
      echo "- Export Borg Backup Data for Node Exporter"
      sudo -H -u "$USER" bash -c "/usr/local/bin/borg_exporter.sh"
    fi

    echo "- STARTING Node Exporter"
    if command -v prometheus-node-exporter >/dev/null 2>&1; then
      sudo -H -u "$USER" bash -c "prometheus-node-exporter --collector.textfile.directory=$NODE_EXPORTER_DIR >/dev/null 2>&1 &"
    elif command -v node_exporter >/dev/null 2>&1; then
      sudo -H -u "$USER" bash -c "node_exporter --collector.textfile.directory=$NODE_EXPORTER_DIR >/dev/null 2>&1 &"
    fi

    if ! pgrep -x crond >/dev/null 2>&1; then
      crond
    fi
    sepurator
  fi
}
###############################################################################
# Main Code
###############################################################################
set_environment_variables_if_not_empty
add_borg_user
add_docker_socket_permission

print_container_info
print_user_info
sepurator
make_and_import_ssh_keys

generate_host_sshkey
sepurator

maintenance_enable
show_timezone_output
run_prometheus_exporter
run_install_script

echo "* Init done! - Starting SSH-Daemon..."
sepurator
exec /usr/sbin/sshd -D -e "$@" 2>&1
