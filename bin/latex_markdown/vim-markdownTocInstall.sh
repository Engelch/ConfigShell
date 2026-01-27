#!/usr/bin/env -S bash --noprofile --norc

target=~/.vim/pack/plugins/start/vim-markdown-toc
if [ -e  "$target" ] ; then
    echo Target environment $target already seems to exist.
    echo Exiting.
    exit 1
else
    mkdir -p  ~/.vim/pack/plugins/start
    git clone https://github.com/mzlogin/vim-markdown-toc.git "$target"
fi
