#!/bin/sh

# Make authorized_keys file
touch "/.ssh/authorized_keys"

# Add User
sh -c "echo '$USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"

echo "ADD USER: $USER WITH UID: $UID"
adduser \
    --disabled-password \
    --gecos "" \
    --home "/" \
    --uid "$UID" \
    "$USER"
echo "$USER:*" | chpasswd
echo "ADD GROUP: $USER WITH GID: $GID"
addgroup -g "$GID" "$USER"

mkdir -p /sshkeys/clients
mkdir -p /sshkeys/host
chown -R "$USER":"$USER" "/sshkeys"

# Add SSH Keys to authorized_keys
FILES=$(ls -1 /sshkeys/clients)
for key in $FILES; do
  echo "Adding SSH-Key $key"
  cat "/sshkeys/clients/$key" >> "/.ssh/authorized_keys"
done
echo "" >> "/.ssh/authorized_keys"

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

exec /usr/sbin/sshd -D -e "$@"
