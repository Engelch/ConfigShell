#!/usr/bin/env bash

Keyfile=~/.ssh/Keys.engelch.d/mac/id_ed25519
[ ! -e "$Keyfile" ]  && echo Keyfile $Keyfile not found && exit 1 
[ "$(ssh-add -l | grep -c engelch@mac160.local)" -eq 0 ] && 1>&2 echo key not loaded, loading... && ssh-add "$Keyfile"
