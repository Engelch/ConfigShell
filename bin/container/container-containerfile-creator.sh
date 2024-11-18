#!/usr/bin/env -S bash --noprofile --norc

1>&2 echo -e '\033[33;7mERROR *****************************************************\033[0m'
1>&2 echo container-containerfile-creator.sh is replaced by either
1>&2 echo   - container-containerfile-creator-jinja.sh 
1>&2 echo   - container-containerfile-creator-j2.sh 
1>&2 echo Use the equivalent one depending on your OS installation.

exit 42
