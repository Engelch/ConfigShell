sudo dnf install mpv texlive pandoc inkscape gimp ghostscript gv d2 httpie texlive-lacheck ImageMagick nmap-ncat psutils tig unzip plantuml git-lfs 7zip antiword
sudo dnf install @virtualization swtpm-tools edk2-ovmf virt-install
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
sudo dnf remove -y nano                 # otherwise, can break vim-default-editor
sudo dnf install vim-default-editor     # vi becomes now also vim
