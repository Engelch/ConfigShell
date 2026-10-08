[ ! -f -f -f -f -f -f -f -f -f /etc/yum.repos.d/netbird.repo ] && sudo tee /etc/yum.repos.d/netbird.repo <<'EOF'
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# DNF 5 (Fedora 41+)
sudo dnf config-manager addrepo --from-repofile=/etc/yum.repos.d/netbird.repo

sudo dnf install netbird                          # CLI only
sudo dnf install libappindicator-gtk3 netbird-ui  # add GUI
