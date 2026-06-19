#!/usr/bin/env bash

sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
sudo dnf install -y vivaldi-stable
