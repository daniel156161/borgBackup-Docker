## SSH Keys

they are into the Container Folder /sshkeys

- **Client Keys** /sshkeys/clients:  add the Public Key with the Hostname.pub
- **Server Keys** /sshkeys/host:  will be here after Server generate them

## BorgBackup Repo

borgBackup Repo can be into any Folder you like but i put it into /backups :3

## Example docker code

run this docker command to get up and running:

```
docker run -dp 3000:22 \
  -e UID=$(id -u) \
  -e GID=$(id -g) \
  -v "$PWD"/sshkeys:/sshkeys \
  -v "$PWD"/backups:/backups \
  daniel156161/borgbackup-ssh:tagname
```

## borgbackup Version into Tags

- **lastest** : borgBackup with Version 1.1.17
- **1.1.17** : borgBackup with Version 1.1.17

more will be come