#!/bin/sh
DOCKER_IMAGE_VERSION="1.0.3"

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
echo "$USER:*" | chpasswd
addgroup -g "$GID" "$USER"
sepurator
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

echo "* Init done! - Starting SSH-Daemon..."
sepurator
exec /usr/sbin/sshd -D -e "$@"
