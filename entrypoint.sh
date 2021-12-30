#!/bin/sh

# Make authorized_keys file
touch "/.ssh/authorized_keys"

# Add User
sh -c "echo '$USER ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
addgroup -g "$GID" "$USER"
adduser \
    --disabled-password \
    --gecos "" \
    --home "/" \
    --ingroup "$USER" \
    --uid "$UID" \
    "$USER"
echo "$USER:*" | chpasswd

# Add SSH Keys to authorized_keys
for key in /sshkeys/*.pub; do
  echo "Adding SSH-Key $key"
  cat "$key" >> "/.ssh/authorized_keys"
done
echo "" >> "/.ssh/authorized_keys"

# Change Ownership of SSH-Keys
chown -R "$USER":"$USER" "/.ssh"
chmod 700 "/.ssh"
chmod 600 "/.ssh/authorized_keys"

# Generate SSH-Keys
ssh-keygen -A
exec /usr/sbin/sshd -D -e "$@"
