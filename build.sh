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

build_docker_image "latest"
run_docker_container

#build_docker_image "1.1.17"