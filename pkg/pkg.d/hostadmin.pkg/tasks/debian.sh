#!/usr/bin/env  -S bash --noprofile --norc

hostAdmin=${HOST_ADMIN:-hostadm} 
echo creating user $hostAdmin...

groupadd $hostAdmin || { echo error creating group $hostAdmin ; exit 1 ; } 
useradd -g $hostAdmin -G sudo -c 'host admin' -m -s /bin/bash $hostAdmin
mkdir /home/$hostAdmin/.ssh || { echo error creating dir /home/$hostAdmin/.ssh ; exit 2 ; } 
cp /root/.ssh/*.pub /home/$hostAdmin/.ssh/ || { echo error creating public ssh files ; exit 3 ; } 
chown -R $hostAdmin /home/$hostAdmin || {  echo error changing ownership of public ssh files ; exit 4 ; } 
chmod 700 /home/$hostAdmin/.ssh || { echo error changing permissions of /home/$hostAdmin/.ssh ; exit 5 ; } 
cat /home/$hostAdmin/.ssh/*.pub >| /home/$hostAdmin/.ssh/authorized_keys || { echo error creating authorized_keys file ; exit 6 ; }
chmod 600 /home/hadm/.ssh/authorized_keys || { echo error changing permissions of /home/$hostAdmin/authorized_keys ; exit 7 ; } 

echo creating sudoers.d/sudo...
echo '%sudo ALL=NOPASSWD: ALL' >| /etc/sudoers.d/sudo || { echo error creating file /etc/sudoers.d/sudo ; exit 10 ; } 
chmod 600 /etc/sudoers.d/sudo || { echo error changing permissions of /etc/sudoers.d/sudo ; exit 11 ; } 
