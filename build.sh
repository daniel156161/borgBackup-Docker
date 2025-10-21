#!/bin/bash
source "../build-functions.sh"
source "../build-config.sh"

DOCKER_IMAGE_NAME="daniel156161/borgbackup-ssh"
DOCKER_CONTAINER_NAME="borgbackup"

function run_docker_container {
  echo "Running..."
  docker run --rm -d \
    -p 2222:22 \
    -p 9100:9100 \
    -e UID=$(id -u) \
    -e GID=$(id -g) \
    -e INTERACTIVE_MODE="true" \
    -e TZ="Europe/Vienna" \
    -e RUN_PROMETHEUS_EXPORTER="15 * * * *" \
    -v "$PWD/sshkeys/clients:/sshkeys/clients:ro" \
    -v "$PWD/sshkeys/host:/sshkeys/host" \
    -v "$PWD/backups:/backups" \
    "$DOCKER_IMAGE_NAME:$GIT_BRANCH"
}

case "$1" in
  run)
    run_docker_container
    ;;
  build)
    build_docker_image "$DOCKER_IMAGE_NAME:$GIT_BRANCH"
    ;;
  *)
    echo "Usage: $0 {run|build}"
    exit 1
    ;;
esac
