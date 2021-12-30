#!/bin/bash

DOCKER_IMAGE_NAME="borgbackup-ssh"
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
  echo "Building..."
  docker build -t "$DOCKER_IMAGE_NAME" .
}

build_docker_image
run_docker_container
