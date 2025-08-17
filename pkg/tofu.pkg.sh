#!/usr/bin/env bash

function opentofuRepo() {
  if [ ! -f  /etc/apt/keyrings/opentofu-repo.gpg ]  ; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://get.opentofu.org/opentofu.gpg | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null
    curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | \
      sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null
    sudo chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
  else
    echo opentofu keyrings existing /etc/apt/keyrings/opentofu-repo.gpg
  fi

  if [ ! -f /etc/apt/sources.list.d/opentofu.list ] ; then
    echo \
      "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | \
    sudo tee /etc/apt/sources.list.d/opentofu.list > /dev/null
    sudo chmod a+r /etc/apt/sources.list.d/opentofu.list
  else
    echo opentofu repo already added as /etc/apt/sources.list.d/opentofu.list
  fi

  sudo apt-get update
  sudo apt-get install -y tofu
}



function main() {
  if [ -z "$1" ] ; then
    command="status"
  else
    command="$1"
  fi
  case "$command" in
    install) opentofuRepo 
      ;;
    status) command -v tofu && echo tofu command found  \
        && [ -f  /etc/apt/keyrings/opentofu-repo.gpg ] && echo '  /etc/apt/keyrings/opentofu-repo.gpg found' \
        && [ ! -f /etc/apt/sources.list.d/opentofu.list ] && echo '/etc/apt/sources.list.d/opentofu.list found'
      command -v tofu || { echo tofu command not found ; exit 1 ; }
      ;;
    *) echo command not found
      exit 1
      ;;
  esac
}




main "$@"


# EOF

