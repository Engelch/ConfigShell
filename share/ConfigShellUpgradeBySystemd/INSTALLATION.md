This directory contains scripts to install ConfigShell on a Linux system.
A new user and group, both named configshell, will be created for it.
The repository will be installed under /opt/ConfigShell.
Systemd timers are used to update the repository clone periodically.

The actual upgrade script is copied into /usr/local/bin to be independent
from the actual contents of the ConfigShell repository.

The default repository is https://github.com/engelch/ConfigShell. Another
repository can be specified using:

```bash
configshellRepo=https://mynewrep.example.com ./configshell-linux-systemd-install.sh
```

You can check the installation by using:

    ```
    sudo systemctl status configshell-upgrade.timer
    ```

The log of a configshell-upgrade run can be checked with the command:

    ```
    sudo journalctl -u configshell-upgrade
    ```

If cloning the ConfigShell repository requires an ssh key, you can follow this approach:

1. create a home-directory for the user configshell
2. add a .ssh directory with the deployment key, e.g. .ssh/deploy
3. add the dot.bashrc as .bashrc and .bash_profile files
4. execute the configshell-linux... installation script.
