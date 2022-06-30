#!/bin/bash

DOCKER_IMAGE_NAME="daniel156161/borgbackup-ssh"
DOCKER_CONTAINER_NAME="borgbackup"

run_docker_container() {
  echo "Running..."
  docker run -dp 3000:22 \
    -e UID=$(id -u) \
    -e GID=$(id -g) \
    -v "$PWD"/sshkeys:/sshkeys \
    -v "$PWD"/backups:/backups \
    "$DOCKER_IMAGE_NAME"
}

build_docker_image() {
  TAG="$1"

  echo "Building..."
  docker build -t "$DOCKER_IMAGE_NAME:$TAG" .
}

case "$1" in
  run)
    run_docker_container
    ;;
  build)
    build_docker_image "latest"
    ;;
  upload)
    build_docker_image "latest"
    docker push "$DOCKER_IMAGE_NAME:latest"
    ;;
  *)
    echo "Usage: $0 {run|build}"
    exit 1
    ;;
esac
