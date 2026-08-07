#!/usr/bin/env bash

echo A directory gitflow-avh will be created in this directory.
echo Press ^c to stop and select to an appropriate parent directory.
read
if [ ! -d gitflow-avh ] ; then
	git clone https://github.com/petervanderdoes/gitflow-avh.git &&
	cd gitflow-avh &&
	sudo make prefix=/usr/local install
else
	echo Directory already exising, pulling and installing
	cd gitflow-avh &&
	git pull &&
	sudo make prefix=/usr/local install
fi
	
