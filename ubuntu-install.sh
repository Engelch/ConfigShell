#!/usr/bin/env sh 

# setup a develop-environment

sudo apt-get -y update
sudo apt-get install -y unzip ansible python3-pip bumpversion ruby gnutls-bin gpg vim python3-jinja2 zsh curl openssl openvpn tree thefuck zsh fish

sudo snap install j2
sudo snap install bruno

sudo snap install --classic go
sudo snap install --classic opentofu
sudo snap install --classic aws-cli
sudo snap install --classic rustup

rustup default stable
rustup update

sudo apt-get -y autoremove
