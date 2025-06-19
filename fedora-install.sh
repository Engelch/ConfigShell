#!/usr/bin/env -S bash --norc --noprofile

sudo dnf -y group install development-tools
sudo dnf install -y ansible ruby zsh tig fish thefuck ripgrep bat fd yq mmv procs tokei
sudo dnf install -y vim-X11 texlive textlive-psutils golang opentofu gh htop xmlstarlet
sudo dnf install -y npm dpkg fakeroot

# vivaldi
sudo dnf config-manager addrepo --from-repofile=https://repo.vivaldi.com/stable/vivaldi-fedora.repo
sudo dnf -y install vivaldi-stable

# Rust
sudo dnf install -y rustup
rustup-ini --no-modify-path

cd
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
[ -d ./aws ] && /bin/rm -fr ./aws awscliv2.zip

echo bruno not installed automatically, flatpak not working
echo You can find the bruno releases at https://github.com/usebruno/bruno/releases

# install yq
machine="$(uname -m)"
[ "$machine" = aarch64 ] && machine=arm64

curl -OLv  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$machine.tar.gz
echo yq last installation steps to be done manually
