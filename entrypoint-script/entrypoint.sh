#!/bin/bash
source "/variables.sh"
##############################################################################################################################
# Funktionen
##############################################################################################################################
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

function add_borg_user {
  if ! id "$USER" &>/dev/null; then
    groupadd -g "$GID" "$USER" >> /dev/null
    useradd -r -u "$UID" -g "$GID" -s "/bin/bash" "$USER" >> /dev/null
    passwd -d "$USER" >> /dev/null
    printf "$USER ALL=(ALL) NOPASSWD: ALL\n" | tee -a /etc/sudoers >> /dev/null
    usermod -d / borg >> /dev/null

    create_folder_and_change_permissions "/.config"
    create_folder_and_change_permissions "/.cache"
    chmod 700 "/.cache"
  fi
}

function make_and_import_ssh_keys {
  local create_folders="0"

  if [ ! -f "/.ssh/authorized_keys" ]; then
    touch "/.ssh/authorized_keys"
  else
    rm "/.ssh/authorized_keys"
    touch "/.ssh/authorized_keys"
  fi

  for key in ${SSH_FOLDERS[@]}; do
    if [ ! -d "${key}" ]; then
      mkdir -p "${key}"
      echo "Created ${key}"
      create_folders="1"
    fi
  done

  #chown -R "$USER":"$USER" "/sshkeys"

  if [ $create_folders == "1" ]; then
    sepurator
  fi

  echo "* IMPORT SSH KEYS"
  echo ""

  FILES=$(ls -1 /sshkeys/clients)
  for key in $FILES; do
    echo "-  Adding SSH-Key $key"
    cat "/sshkeys/clients/$key" >> "/.ssh/authorized_keys"
    echo "" >> "/.ssh/authorized_keys"
  done

  chown -R "$USER":"$USER" "/.ssh"
  chmod 700 "/.ssh"
  chmod 600 "/.ssh/authorized_keys"
}

function print_message {
  echo ""
  echo "- $1"
  echo ""
}

function generate_host_sshkey {
  local generated_keys="0"
  echo "* GENERATE HOST SSH-KEYs"
  # Generate SSH-Keys
  if [ ! -f "/sshkeys/host/ssh_host_rsa_key" ]; then
    print_message "HOST SSH-KEY RSA not found, generating..."
    ssh-keygen -t rsa -b 4096 -f "/sshkeys/host/ssh_host_rsa_key" -N ""
    print_message "HOST SSH-KEY RSA Generated"
    generated_keys="1"
  fi
  if [ ! -f "/sshkeys/host/ssh_host_ecdsa_key" ]; then
    print_message "HOST SSH-KEY ECDSA not found, generating..."
    ssh-keygen -t ecdsa -b 521 -f "/sshkeys/host/ssh_host_ecdsa_key" -N ""
    print_message "HOST SSH-KEY ECDSA Generated"
    generated_keys="1"
  fi
  if [ ! -f "/sshkeys/host/ssh_host_ed25519_key" ]; then
    print_message "HOST SSH-KEY ED25519 not found, generating..."
    ssh-keygen -t ed25519 -b 521 -f "/sshkeys/host/ssh_host_ed25519_key" -N ""
    print_message "HOST SSH-KEY ED25519 Generated"
    generated_keys="1"
  fi

  if [ "$generated_keys" == "0" ]; then
    echo ""
    echo "- HOST SSH-KEYs already exist"
  fi

  chown -R "$USER":"$USER" "/sshkeys/host"
}

function maintenance_enable {
  if [ "$MAINTENANCE_ENABLE" != "false" ]; then
    echo "* MAINTENANCE MODE - ENABLED"
    echo ""
    if [ -f "/crontab.txt" ]; then
      crontab "/crontab.txt"
      crond -i 2> /dev/null
      echo "- Crontab loaded successfully"
    else
      echo "- Can not find /crontab.txt"
    fi
    sepurator
  fi
}

function set_timezone {
  if [ "$TZ" != "" ]; then
    echo "* Setting Timezone to $TZ"
    echo "TZ=$TZ" > /etc/environment
  else
    echo "* Timezone not set - Use UTC Time"
  fi
  sepurator
}

function run_install_script {
  if [ "$RUN_INSTALL_SCRIPT" != "false" ]; then
    if [ ! -f "/.runnedInstall" ]; then
      echo "* RUNNING INSTALL SCRIPT"
      sepurator
      sh "$RUN_INSTALL_SCRIPT"
      echo ""
      sepurator
      touch "/.runnedInstall"
    fi
  fi
}

function create_folder_and_change_permissions {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
  chown -R "$USER":"$USER" "$1"
}

function run_teleport_server() {
  if [ -f "/etc/teleport.yaml" ]; then
    echo "* STARTING Teleport Server"
    teleport start -c /etc/teleport.yaml > /var/log/teleport.log 2>&1 &
    sepurator
	fi
}

function run_prometheus_exporter() {
  if [ "$RUN_PROMETHEUS_EXPORTER" != "false" ]; then
    create_folder_and_change_permissions "/var/log/"

    echo "* STARTING Prometheus Exporter for Borg Backup"
    echo ""

    crontab -l > /tmp/cron_bkp
    echo "" >> /tmp/cron_bkp

    echo "- Add Cronjob to Crontab"
    echo "$RUN_PROMETHEUS_EXPORTER su -c '/usr/local/bin/borg_exporter.sh 2>&1' -s /bin/bash borg" >> /tmp/cron_bkp
    crontab /tmp/cron_bkp
    rm /tmp/cron_bkp

    if [ ! -f "/var/log/borg_exporter.prom" ]; then
      echo "- Export Borg Backup Data for Node Exporter"
      sudo -H -u "$USER" bash -c "/usr/local/bin/borg_exporter.sh"
    fi

    echo "- STARTING Node Exporter"
    sudo -H -u "$USER" bash -c "prometheus-node-exporter --collector.textfile.directory=$NODE_EXPORTER_DIR > /dev/null 2>&1 &"
    sepurator
  fi
}
##############################################################################################################################
# Main Code
##############################################################################################################################
add_borg_user

print_container_info
print_user_info
sepurator
make_and_import_ssh_keys
sepurator
generate_host_sshkey
sepurator

maintenance_enable
set_timezone
run_teleport_server
run_prometheus_exporter
run_install_script

echo "* Init done! - Starting SSH-Daemon..."
sepurator
echo ""
exec /usr/sbin/sshd -D -e "$@" 2> /var/log/sshd.log
