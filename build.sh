#!/bin/bash

DOCKER_IMAGE_NAME="daniel156161/borgbackup-ssh"
DOCKER_CONTAINER_NAME="borgbackup"
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

run_docker_container() {
  echo "Running..."
  docker run -dp 3000:22 \
    -e UID=$(id -u) \
    -e GID=$(id -g) \
    -e MAINTENANCE_ENABLE="true" \
    -e INTERACTIVE_MODE="true" \
    -e TZ="Europe/Vienna" \
    -v "$PWD"/Testing/crontab.txt:/crontab.txt \
    -v "$PWD"/Testing/test_script.sh:/test_script.sh \
    -v "$PWD"/sshkeys/clients:/sshkeys/clients \
    -v "$PWD"/backups:/backups \
    "$DOCKER_IMAGE_NAME":"$GIT_BRANCH"
}

build_docker_image() {
  TAG="$1"

  echo "Building..."
  docker build -t "$DOCKER_IMAGE_NAME:$TAG" .
}

if [ "$GIT_BRANCH" == "main" ]; then
  GIT_BRANCH="latest"
fi

case "$1" in
  run)
    run_docker_container
    ;;
  build)
    build_docker_image "$GIT_BRANCH"
    ;;
  upload)
    build_docker_image "$GIT_BRANCH"
    docker push "$DOCKER_IMAGE_NAME:$GIT_BRANCH"
    ;;
  test)
    build_docker_image "$GIT_BRANCH"
    run_docker_container
    ;;
  *)
    echo "Usage: $0 {run|build|test|upload}"
    exit 1
    ;;
esac
