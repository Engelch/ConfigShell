#!/usr/bin/env bash
# ok shellcheck
# --u250110

set -u

readonly keyRingFile=/usr/share/keyrings/brave-browser-archive-keyring.gpg
readonly sourceRepoFile=/etc/apt/sources.list.d/brave-browser-release.list

function delFile() {
	    [ ! -f "$1" ] && 1>&2 echo "File $1 not found" && return 1
        [ -f "$1" ] && { sudo /bin/rm -f "$1" ; return $? ; }
}

##################### Arg parsing

# -f or --force to force installation
force=
[ "${1:-}" = -f ] || [ "${1:-}" = --force ] && force=TRUE && shift
# check for uninstall mode
uninstall=
[ "${1:-}" = -r ] || [ "${1:-}" = --uninstall ] && uninstall=TRUE && shift
# still an argument on the CLI => error
[ -n "${1:-}" ] && 1>&2 echo Non support argument "$*" && exit 1

#####################

if [ -n "$uninstall" ] ; then
	delFile "$keyRingFile"
	delFile "$sourceRepoFile"
	sudo apt-get purge -y brave-browser
	sudo apt-get -y autoremove
else # installation
	curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | sudo tee "$keyRingFile"

	[ -r "$sourceRepoFile" ] && [ -n "$force" ] && sudo /bin/rm -f "$sourceRepoFile"
	if [ ! -r "$sourceRepoFile" ] ; then
		echo "deb [signed-by=$keyRingFile] https://brave-browser-apt-release.s3.brave.com/ stable main"| sudo tee "$sourceRepoFile"
	fi

	sudo apt-get update && sudo apt-get install -y brave-browser
fi

# EOF
