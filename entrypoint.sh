#!/bin/bash
source "/variables.sh"
##############################################################################################################################
# Funktionen
##############################################################################################################################
function sepurator {
  echo "==============================================================================="
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

function add_borg_user {
  if ! id "borg" &>/dev/null; then
    sh -c "echo '$USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
    adduser \
    -s /bin/bash \
    --disabled-password \
    --gecos "" \
    --home "/" \
    --uid "$UID" \
    "$USER"
    echo "$USER:*" | chpasswd 2>> /dev/null
    addgroup -g "$GID" "$USER"  2>> /dev/null
  fi
}

function make_and_import_ssh_keys {
  local create_folders="0"
  touch "/.ssh/authorized_keys"

  for key in ${SSH_FOLDERS[@]}; do
    if [ ! -d "${key}" ]; then
      mkdir -p "${key}"
      echo "Created ${key}"
      create_folders="1"
    fi
  done

  chown -R "$USER":"$USER" "/sshkeys"

  if [ $create_folders == "1" ]; then
    sepurator
  fi

  echo "* IMPORT SSH KEYS"
  echo ""

  FILES=$(ls -1 /sshkeys/clients)
  for key in $FILES; do
    echo "-  Adding SSH-Key $key"
    cat "/sshkeys/clients/$key" > "/.ssh/authorized_keys"
  done
  echo "" >> "/.ssh/authorized_keys"

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
      /usr/bin/crontab "/crontab.txt"
      /usr/sbin/crond -b
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

echo "* Init done! - Starting SSH-Daemon..."
sepurator
echo ""
exec /usr/sbin/sshd -D -e "$@" 2> /logs/sshd.log
