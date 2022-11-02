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

## Use after setup
```
export BORG_REPO='ssh://borg@localhost:3000/backups'
borg init -e none
# any borg command you like
```


## SSH Keys
they are into the Container Folder /sshkeys

- **Client Keys** /sshkeys/clients:  add the Public Key with the Hostname.pub
- **Server Keys** /sshkeys/host:  will be here after Server generate them


## BorgBackup Repo

borgBackup Repo can be into any Folder you like but i put it into /backups :3

## Maintain Borg Repo - not into 1.1.17
Use ENV MAINTENANCE_ENABLE="true" and bind your contab file into /crontab.txt and bind your script to / too its easier with the Crontab file

## Logs - not into 1.1.17
Create New Volumen into /logs if you like to log anything or get the logs

## Set Timezone - not into 1.1.17
Use ENV TZ="Your time zone" if not set will use UTC

## Export Data to Grafana and Prometheus - not into 1.1.17
Borg exporter for Prometheus from https://github.com/mad-ady/prometheus-borg-exporter

Use ENV RUN_PROMETHEUS_EXPORTER and set it to any CRONJOB TASK like ```0 * * * *``` to update the /logs/borg_exporter.prom every hour
Config is into ```/etc/borg_exporter.rc``` sample config:
```
BORG_PASSPHRASE=""
REPOSITORY=""
PUSHGATEWAY_URL=""
BASEREPODIR="/backups"
```

## borgbackup Version into Tags

| TAG | Borg Backup Version | Alpine Version |
| ----------- | ----------- |  ----------- |
| lastest | 1.2.1                         | edge                 |
| stable    | 1.2.0                         | latest                  |
| 1.1.17  | 1.1.17                       | not know any more |

more will be come
