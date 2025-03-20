1. copy the files to /etc/systemd/system
2. sudo systemctl daemon-reload
3. useradd -g adm -r configshell # no homedir
4. chown -R configshell:adm /opt/ConfigShell/.
3. sudo systemctl enable configshell-upgrade.timer
4. sudo systemctl start  configshell-upgrade.timer
5. check the status

    ```
    sudo systemctl status configshell-upgrade.timer configshell-upgrade.service
    ```
