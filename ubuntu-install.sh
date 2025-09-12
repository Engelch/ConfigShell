#!/usr/bin/env bash 

# setup a develop-environment
#

_installMode="${ubuntuInstallationMode:-repo} 

case "${_installMode}" in
  repo) echo Installation mode using repositories.
    ;;
  snap) echo Installation mode using snap.
    ;;
  *) echo Unsupport installation mode: ${_installMode} 
     exit 1
    ;;
esac

function opentofuRepo() {
  if [ ! -f  /etc/apt/keyrings ]  ; then
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://get.opentofu.org/opentofu.gpg | sudo tee /etc/apt/keyrings/opentofu.gpg >/dev/null
    curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | \
      sudo gpg --no-tty --batch --dearmor -o /etc/apt/keyrings/opentofu-repo.gpg >/dev/null
    sudo chmod a+r /etc/apt/keyrings/opentofu.gpg /etc/apt/keyrings/opentofu-repo.gpg
  else
    echo opentofu keyrings existing
  fi

  if [ ! -f /etc/apt/sources.list.d/opentofu.list ] ; then
    echo \
      "deb [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main
deb-src [signed-by=/etc/apt/keyrings/opentofu.gpg,/etc/apt/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | \
    sudo tee /etc/apt/sources.list.d/opentofu.list > /dev/null
    sudo chmod a+r /etc/apt/sources.list.d/opentofu.list
  fi

  sudo apt-get update
  sudo apt-get install -y tofu
}

sudo apt-get -y update
sudo apt-get install -y unzip ansible python3-pip bumpversion ruby gnutls-bin gpg vim python3-jinja2 zsh curl openssl openvpn tree thefuck zsh fish tig

case "${_installMode}" in
  repo) :
      sudo snap install j2
      sudo snap install bruno

      sudo snap install --classic go
      sudo snap install --classic opentofu
      sudo snap install --classic aws-cli
      sudo snap install --classic rustup
      ;;
  snap) :
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
      ;;
esac

rustup default stable
rustup update

sudo apt-get -y autoremove
