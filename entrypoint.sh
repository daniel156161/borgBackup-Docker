#!/bin/sh
DOCKER_IMAGE_VERSION="1.0.7"

sepurator() {
  echo "==============================================================================="
}

sepurator
BORG_VERSION=$(borg -V)
echo "* BorgServer powered by $BORG_VERSION"
echo "* Image Hostname: $HOSTNAME"
echo "* Image Version: $DOCKER_IMAGE_VERSION"
sepurator

# Make authorized_keys file
touch "/.ssh/authorized_keys"

# Add User
sh -c "echo '$USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"

adduser \
  --disabled-password \
  --gecos "" \
  --home "/" \
  --uid "$UID" \
  "$USER"
echo "$USER:*" | chpasswd 2>> /logs/user.log
addgroup -g "$GID" "$USER"  2>> /logs/user.log

echo "* USER: $USER ID: $UID"
echo "* GROUP: $USER GID: $GID"
sepurator

mkdir -p /sshkeys/clients
mkdir -p /sshkeys/host
chown -R "$USER":"$USER" "/sshkeys"

echo "* IMPORT SSH KEYS"
echo ""
# Add SSH Keys to authorized_keys
FILES=$(ls -1 /sshkeys/clients)
for key in $FILES; do
  echo "-  Adding SSH-Key $key"
  cat "/sshkeys/clients/$key" >> "/.ssh/authorized_keys"
done
echo "" >> "/.ssh/authorized_keys"
sepurator

# Change Ownership of SSH-Keys
chown -R "$USER":"$USER" "/.ssh"
chmod 700 "/.ssh"
chmod 600 "/.ssh/authorized_keys"

# Generate SSH-Keys
if [ ! -f "/sshkeys/host/ssh_host_rsa_key" ]; then
  ssh-keygen -t rsa -b 4096 -f "/sshkeys/host/ssh_host_rsa_key" -N ""
fi
if [ ! -f "/sshkeys/host/ssh_host_ecdsa_key" ]; then
  ssh-keygen -t ecdsa -b 521 -f "/sshkeys/host/ssh_host_ecdsa_key" -N ""
fi
if [ ! -f "/sshkeys/host/ssh_host_ed25519_key" ]; then
  ssh-keygen -t ed25519 -b 521 -f "/sshkeys/host/ssh_host_ed25519_key" -N ""
fi

chown -R "$USER":"$USER" "/sshkeys/host"

# MAINTENANCE_ENABLE of Borg Repository
if [ "$MAINTENANCE_ENABLE" != "false" ]; then
  if [ -f "/crontab.txt" ]; then
    /usr/bin/crontab "/crontab.txt"
    /usr/sbin/crond -b
    echo "* Crontab loaded successfully"
  else
    echo "* Can not find /crontab.txt"
  fi
  sepurator
fi

if [ "$TZ" != "" ]; then
  echo "* Setting Timezone to $TZ"
  echo "TZ=$TZ" > /etc/environment
else
  echo "* Timezone not set - Use UTC Time"
fi
sepurator

echo "* Init done! - Starting SSH-Daemon..."
sepurator
exec /usr/sbin/sshd -D -e "$@" 2>> /logs/sshd.log
