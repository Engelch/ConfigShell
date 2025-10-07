#!/usr/bin/env bash

##########################################################################################
# idempotent execution for adding a user
##########################################################################################
#   detect the group for adding users to the sudo command
#   make sure that the value is empty and no other variable with the same name from outside,
#   e.g. environment variables, influences the evaluation.
#   We expect that no system contains the groups wheel AND sudo.

_sudoType=
grep ^wheel /etc/group &>/dev/null && echo wheel system && _sudoType=wheel
grep ^sudo  /etc/group &>/dev/null && echo sudo system  && _sudoType=sudo

#   If the group could be detected, then the variable _sudoType is set. Else, we have an error.
#   Make sure that the current user is added to this group. The usermod command itself is idempotent

[ -n "$_sudoType" ] && sudo usermod -a -G "$_sudoType" "$USER" 
[ -z "$_sudoType" ] && echo unclear sudo mechanism, please check && exit 99 

##########################################################################################
# dnf addition of packages
##########################################################################################

sudo dnf -y group install development-tools
sudo dnf remove  -y podman podman-compose
sudo dnf install -y yq jq bat tig mmv xmlstarlet
sudo dnf install -y fish vim git-lfs procs du-dust lsb_release vim-X11 gnutls openvpn tree
sudo dnf install -y golang-bin rust cargo tokei java-25-openjdk-devel ruby dotnet-sdk-9.0
sudo dnf install -y openssh-server htop telnet ansible opentofu npm
sudo dnf install -y awscli2 kubernetes1.34-client
sudo dnf install -y texlive vim-latex vim-latex-doc pandoc texlive-psutils
# TODO bruno 2510: no flatpak, no rpm pkg

##########################################################################################
# add Docker
##########################################################################################
#     Fri 03 Oct 2025 06:09:10 PM CEST
#     If the docker-ce.repo file was found, we expect that this was already sucessfully 
#     executed before. If not, delete the file for a new execution.

if [ ! -e /etc/yum.repos.d/docker-ce.repo ] ; then
   sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
   sudo dnf install docker-ce docker-ce-cli
   sudo systemctl enable --now docker
   sudo usermod -a -G docker $USER     # usermod is an idempotent command
fi

##########################################################################################
# prepare vivaldi-stable installation
##########################################################################################

sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo

##########################################################################################
# eza installation via cargo
##########################################################################################

if which cargo-install-update &>/dev/null ; then
   cargo-install-update install-update --all
else
   cargo install eza
   cargo install cargo-update 
fi

##########################################################################################
# give a chance to stop after dnf installation and before flatpak installation
##########################################################################################

# echo DNF installation done, press ENTER to continue with flatpak installations...
# read

##########################################################################################
# flatpak based installation
##########################################################################################

# remove flatpaks
#  org.freedesktop.Sdk.Extension.dotnet

for app in \
       com.brave.Browser \
       org.audacityteam.Audacity \
       com.jetbrains.GoLand \
       com.jetbrains.DataGrip \
       com.jetbrains.RubyMine \
       com.jetbrains.RustRover \
       com.jetbrains.IntelliJ-IDEA-Ultimate \
       md.obsidian.Obsidian \
       org.gnome.GHex \
       com.ktechpit.whatsie
do
   echo Working on $app...
   sudo flatpak install --or-update -y --noninteractive flathub $app
done

##########################################################################################
# EOF
