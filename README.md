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
## Maintain Borg Repo
Use ENV MAINTENANCE_ENABLE="true" and bind your contab file into /crontab.txt and bind your script to / too its easier with the Crontab file

## Logs
Create New Volumen into /logs if you like to log anything

## borgbackup Version into Tags

| TAG | Borg Backup Version | Alpine Version |
| ----------- | ----------- |  ----------- |
| lastest | 1.2.1                         | latest                 |
| 1.2.0    | 1.2.0                         | 3.16                   |
| 1.1.17  | 1.1.17                       | not know any more |

more will be come