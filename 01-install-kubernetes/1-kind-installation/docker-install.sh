#!/bin/bash

# update ubuntu packages
sudo apt update && sudo apt upgrade -y

# install docker
sudo apt install docker.io -y

# enable docker service
sudo systemctl enable docker

# start docker
sudo systemctl start docker

# add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# verify docker installation
docker --version