#!/usr/bin/env bash

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
# dnf addition of packages
##########################################################################################


# ADDITION --260611
sudo dnf -y group install development-tools
sudo dnf install -y yq jq bat tig mmv xmlstarlet gnome-terminal
sudo dnf install -y fish vim git-lfs procs du-dust lsb_release vim-X11 gnutls openvpn tree
sudo dnf install -y golang-bin rust cargo tokei java-25-openjdk-devel ruby dotnet-sdk-9.0
sudo dnf install -y openssh-server htop telnet ansible opentofu npm ripgrep
sudo dnf install -y awscli2 kubernetes1.34-client bumpversion mc
sudo dnf install -y texlive vim-latex vim-latex-doc pandoc texlive-psutils bumpversion
sudo dnf install -y wl-clipboard libxkbcommon-devel dbus-devel wxGTK-devel gcc-c++ # espanso rust compilation

# install cosmic desktop - nice looking, but does not support resize of the VM window --251027
#  sudo dnf copr enable -y ryanabx/cosmic-epoch
#  sudo dnf install -y cosmic-desktop

sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
echo Vivaldi repo added, you still have to install the package if you like

##########################################################################################
# eza installation via cargo
##########################################################################################

if which cargo-install-update &>/dev/null ; then
   cargo-install-update install-update --all
else
   cargo install eza
   cargo install cargo-update 
fi

