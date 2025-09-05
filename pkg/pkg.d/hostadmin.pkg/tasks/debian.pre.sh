#!/usr/bin/env bash

! [ -d /root/.ssh/. ] && echo ERROR /root/.ssh not existing && exit 1

[ $(find /root/.ssh/ -name \*.pub | wc -l) -eq 0 ] && echo 'ERROR: no <user>.pub ssh keys found in /root/.ssh for host admin installation' &&
   echo 'ERROR: these users are allowed log in into the host admin account' && exit 2

exit 0

