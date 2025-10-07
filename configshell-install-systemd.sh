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
   repo="$1"
   [ -z "$1" ] && errorExit 23 remote repo not passed as an argument
   [ -d /opt/ConfigShell/. ] && errorExit 1 /opt/ConfigShell already existing, delete it for reinstallation
   sudo mkdir /opt/ConfigShell || errorExit 20 cannot create /opt/ConfigShell
   sudo chmod 777 /opt/ConfigShell
   sudo useradd -s /bin/bash -m configshell || { cleanUpOnError ; errorExit 24 user creation failed ; }
   sudo groupadd configshell
   git clone --depth 1 -b master "$repo" /opt/ConfigShell || { cleanUpOnError ; errorExit 22 cannot clone ConfigShell ; }
   sudo chown -R configshell:configshell /opt/ConfigShell /home/configshell || errorExit 21 error executing chown with code $?
   sudo chmod 755 /opt/ConfigShell
}

function cleanUpOnError() {
   echo Deleting ConfigShell installation...
	sudo /bin/rm -fr /opt/ConfigShell /home/configshell
	sudo userdel -f configshell
	sudo groupdel -f configshell
	sudo systemctl disable --now onfigshell-upgrade.timer
	sudo systemctl daemon-reload
	find /etc/systemd/system -name configshell\* -print | xargs sudo /bin/rm -f
}

function configureConfigShellUser() {
   id=$1
   sudo mkdir -p /home/configshell/.ssh || { cleanUpOnError ; errorExit 25 .ssh creation failed ; }
   sudo chmod 700 /home/configshell/.ssh || { cleanUpOnError ; errorExit 29 .ssh permission change failed ; }
   local file=$$.config
   echo 'Host *
    AddKeysToAgent yes
    Compression yes
    ConnectTimeout 300
    ConnectionAttempts 10
    ControlMaster auto
    ControlPersist 900
    ForwardAgent yes
    IgnoreUnknown UseKeychain
    PubkeyAcceptedKeyTypes +ssh-rsa
    ServerAliveCountMax 60
    ServerAliveInterval 2
    StrictHostKeyChecking no
    TCPKeepalive yes
    UseKeychain yes
    UserKnownHostsFile /dev/null
' > "$file"
   sudo /bin/mv "$file" /home/configshell/.ssh/config || { cleanUpOnError ; errorExit 26 config file creation failed ; }
   sudo chmod 600  /home/configshell/.ssh/config || { cleanUpOnError ; errorExit 27 cannot change perms of config file ; }
   if test -n "$id" ; then
	[ ! -r "$id" ] && { cleanUpOnError ; errorExit 27 cannot read id file ; }
   	sudo /bin/cp "$id" /home/configshell/.ssh/id_rsa || { cleanUpOnError ; errorExit 28 error creating id file ; }
   fi
   sudo chmod 600 /home/configshell/.ssh/id_rsa || { cleanUpOnError ; errorExit 29 cannot change perms of id_rsa ; }
   sudo chown -R configshell /home/configshell || { cleanUpOnError ; errorExit 30 cannot change ownership of id_rsa ; }
}

# no help yet
# no arguments:                     install using github.com and expect that the repo is publically readable
# -r repo                           specify another repo
# -r repo ssh-private-key-file      specify another repo and and ssh private key file to be used for cloning and pulling
#                                   This is required for some private clones of the repository
# -d                                delete a complete installation of ConfigShell, but not local files added to the user
# -2                                Debug only, just work on user creation, leave out the step of cloning ConfigShell,...
function main() {
   remote_repo=https://github.com/engelch/ConfigShell
   [ "$1" = '-d' ] && cleanUpOnError && exit 9
   [ "$1" = '-r' ] && shift && remote_repo="$1"
   [ -z "$remote_repo" ] && errorExit 2 remote repository overwritten but not specified
   # -2 skip configshell installation and just work on user installation,... for debugging purposes
   [ "$1" != '-2' ] && installConfigShell "$remote_repo" # exit 20-29
   configureConfigShellUser $2
   createSystemdTimer
}

main "$@"

