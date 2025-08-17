#!/usr/bin/env bash


function loadLib() {
	########################################################################################
	# ConfigShell lib 1.1 (codebase 1.0.0)
	bashLib="/opt/ConfigShell/lib/bashlib.sh"
	[ ! -f "$bashLib" ] && 1>&2 echo "bash-library $bashLib not found" && exit 127
	# shellcheck source=/opt/ConfigShell/lib/bashlib.sh
	source "$bashLib"
	unset bashLib
}

function opentofuRepoInstall() {
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://get.opentofu.org/opentofu.gpg | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null
  curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | \
    sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null
  
  sudo rsync -av "${appDir}/tofu.pkg.d/files/" /
  sudo chmod 644 /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
  sudo chown root:root /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
  sudo chmod 644 /etc/apt/sources.list.d/opentofu.list
  sudo chown root:root /etc/apt/sources.list.d/opentofu.list

  sudo apt-get update
  sudo apt-get install -y tofu
  return $?
}

function opentofuRepoStatus() {
  which tofu &>/dev/null && echo -n tofu command found: \
        && which tofu \
        && [ -f /etc/apt/keyrings/opentofu.gpg ] && echo '  /etc/apt/keyrings/opentofu.gpg found' \
        && [ -f /etc/apt/keyrings/opentofu-repo.gpg ] && echo '  /etc/apt/keyrings/opentofu-repo.gpg found' \
        && [ -f /etc/apt/sources.list.d/opentofu.list ] && echo '  /etc/apt/sources.list.d/opentofu.list found' \
	      && echo -n '  ' && dpkg -l tofu | grep ii 
  which tofu &>/dev/null || errorExit 1 tofu command not found 
}

function recordSuccess() {
  [ ! -d /etc/configshell.pkg/installed ] && sudo mkdir -p /etc/configshell.pkg/installed 
  [ ! -d /etc/configshell.pkg/installed ] && errorExit 10 cannot create configshell.pkg/installed
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date::$(dpkg -l $1 | grep ^ii)  | sudo tee /etc/configshell.pkg/installed/$1.$_date
  find /etc/configshell.pkg/error/$1\* -exec /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/uninstalled/$1\* -exec /bin/rm -f {} \; &>/dev/null
}

function recordError() {
  [ ! -d /etc/configshell.pkg/error ] && sudo mkdir -p /etc/configshell.pkg/error 
  [ ! -d /etc/configshell.pkg/error ] && errorExit 11 cannot create configshell.pkg/error
  _date="$(date --utc '+%y%m%d_%H:%M')"
  echo $_date::$1  | sudo tee /etc/configshell.pkg/error/$1.$_date
  find /etc/configshell.pkg/success/$1\* -exec /bin/rm -f {} \; &>/dev/null
  find /etc/configshell.pkg/uninstalled/$1\* -exec /bin/rm -f {} \; &>/dev/null
}


function main() {
  loadLib
  appDir="$(dirname "$0")"
  [ ! -d "$appDir/tofu.pkg.d/" ] && errorExit 3 tofu.pkg.d not found
  if [ -z "$1" ] ; then
    command="status"
  else
    command="$1"
  fi
  case "$command" in
    force-install) opentofuRepoInstall; res=$?
	    [ "$res" -eq 0 ] && recordSuccess tofu
	    [ "$res" -ne 0 ] && recordError tofu
      ;;
    install) 
      which tofu &>/dev/null && echo tofu already found.
      which tofu &>/dev/null || { opentofuRepoInstall ; res=$?
	      [ "$res" -eq 0 ] && recordSuccess tofu
	      [ "$res" -ne 0 ] && recordError tofu
      }
      ;;
    status) opentofuRepoStatus 
      ;;
    version) echo 0.0.3
      ;;
    *) errorExit 9 'command mode not found, currently supported: install, force-install, status, version'
      ;;
  esac
}




main "$@"


# EOF

