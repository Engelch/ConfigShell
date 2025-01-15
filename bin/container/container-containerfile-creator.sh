#!/usr/bin/env -S bash --noprofile --norc

# 1>&2 echo -e '\033[33;7mERROR *****************************************************\033[0m'
1>&2 echo container-containerfile-creator.sh is replaced by either
1>&2 echo   - container-containerfile-creator-jinja2.sh 
1>&2 echo   - container-containerfile-creator-j2.sh 
1>&2 echo Use the equivalent one depending on your OS installation.
1>&2 echo 
1>&2 echo This script will do auto determination of jinja implementation

for app in jinja2 j2 ; do 
    which $app &>/dev/null && jinja=$app && echo -e "app found \033[33;7m$jinja\033[0m" && break 
done
[ -z "${jinja:-}" ] && 1>&2 echo "Neither jinja2 nor j2 could be found" && exit 42
echo running container-containerfile-creator-$app.sh
exec container-containerfile-creator-$app.sh

