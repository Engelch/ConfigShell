#!/usr/bin/env bash

# 251023
# - adding gnome-terminal
# 251021
# - installation of wheel/sudo file added about line 21-28
# 251010-00

##########################################################################################
# idempotent execution for adding a user
##########################################################################################
#   detect the group for adding users to the sudo command - clear for fedora, but code is
#   also usable for Debian- and Ubuntu-based systems.
#   Make sure that the value is empty and no other variable with the same name from outside,
#   e.g. environment variables, influences the evaluation.
#   We expect that no system contains both the groups wheel AND sudo.

_sudoType=
grep ^wheel /etc/group &>/dev/null && echo wheel system && _sudoType=wheel
grep ^sudo  /etc/group &>/dev/null && echo sudo system  && _sudoType=sudo

#   If the group could be detected, then the variable _sudoType is set. Else, we have an error.
#   Make sure that the current user is added to this group. The usermod command itself is idempotent

[ -n "$_sudoType" ] && sudo usermod -a -G "$_sudoType" "$USER" 
[ -z "$_sudoType" ] && echo unclear sudo mechanism, please check && exit 99 

sudo bash -c "test -f /etc/sudoers.d/$_sudoType"
sudoRes=$?
echo sudoRes is $sudoRes

if [ "$sudoRes" -ne 0  ] ; then
   sudo echo "%$_sudoType ALL=(ALL) NOPASSWD:ALL" >| /etc/sudoers.d/$_sudoType
else
   echo sudo setup already existing
fi


##########################################################################################
# add Docker
##########################################################################################
#     Fri 03 Oct 2025 06:09:10 PM CEST
#     If the docker-ce.repo file was found, we expect that this was already sucessfully 
#     executed before. If not, delete the file for a new execution.

# REMOVAL
sudo dnf remove  -y podman podman-compose 
if [ ! -e /etc/yum.repos.d/docker-ce.repo ] ; then
   sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
   sudo dnf install docker-ce docker-ce-cli
   sudo systemctl enable --now docker
   sudo usermod -a -G docker $USER     # usermod is an idempotent command
fi

##########################################################################################
# EOF
