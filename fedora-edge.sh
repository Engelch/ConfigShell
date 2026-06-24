#!/usr/bin/env bash

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

grep -q microsoft.asc /etc/yum.repos.d/microsoft-edge.repo || { 
	echo installing edge-repo
	printf '%s\n' \
'[microsoft-edge]' \
'name=microsoft-edge' \
'baseurl=https://packages.microsoft.com/yumrepos/edge-stable' \
'enabled=1' \
'gpgcheck=1' \
'gpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee /etc/yum.repos.d/microsoft-edge.repo > /dev/null
}

sudo dnf makecache --refresh

sudo dnf install microsoft-edge-stable

