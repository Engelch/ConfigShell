#!/usr/bin/env bash

function errorExit() {
   code="$1"
   shift
   echo "$*" 1>&2
   exit "$code"
}

# EXIT 40-49
function createSystemdTimer() {
  echo Setting up systemd
  [ ! -d /etc/systemd/system ] && errorExit 40 cannot find dir /etc/systemd/system
  [ ! -d /opt/ConfigShell/share/ConfigShellUpgradeBySystemd/ ] && errorExit 41 cannot find dir /opt/ConfigShell/share/ConfigShellUpgradeBySy
stemd/
  # no -a to avoid -go group+owner
  sudo rsync -pt --copy-links /opt/ConfigShell/share/ConfigShellUpgradeBySystemd/configshell-upgrade.sh /usr/local/bin || \
    errorExit 44 error rsyncing confighsell-upgrade.sh
  sudo rsync -rlptD --copy-links /opt/ConfigShell/share/ConfigShellUpgradeBySystemd/configshell-upgrade.* /etc/systemd/system || \
    errorExit 42 error rsyncing systemd unit files
  sudo chown root:root /etc/systemd/system/configshell-upgrade.* || errorExit 43 cannot normalise ownership of /etc/systemd/system/configshell..
  sudo systemctl daemon-reload
  sudo systemctl enable --now configshell-upgrade.timer || errorExit 45 cannot enable + start configshell-upgrade.timer
  sudo systemctl status configshell-upgrade.timer
}

# ConfigShell not found, install it. 
# EXIT 20-29
function installConfigShell() { 
  sudo mkdir /opt/ConfigShell || errorExit 20 cannot create /opt/ConfigShell
  sudo useradd configshell 
  sudo groupadd configshell
  sudo git clone --depth 1 -b master https://github.com/engelch/ConfigShell /opt/ConfigShell || errorExit 22 cannot clone ConfigShell
  sudo chown -R configshell:configshell /opt/ConfigShell || errorExit 21 error executing chown with code $?
}


function main() {
   [ -d /opt/ConfigShell/. ] && errorExit 1 /opt/ConfigShell already existing, delete it for reinstallation
   installConfigShell # exit 20-29
   createSystemdTimer
}

main "$@"

