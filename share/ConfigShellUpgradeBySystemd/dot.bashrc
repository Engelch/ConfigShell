# This file is required if a key is required to clone the repository.
#
# Also copy it as .bash_profile as either .bash_profile is loaded for
# a login shell or .bashrc for an interactive one.

eval $(ssh-agent -s)
ssh-add ~/.ssh/deployKey
