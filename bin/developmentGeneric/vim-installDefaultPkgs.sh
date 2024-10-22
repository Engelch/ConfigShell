#!/usr/bin/env -S bash --norc --noprofile

function cdOrExit() {
   cd "$1" || { 1>&2 echo "cannot cd to $1" ; exit 1 ; }
}

function mkCdOrExit() {
   mkdir -p "$1" || { 1>&2 echo "cannot mkdir -p $1" ; exit 1 ; }
   cdOrExit "$1"
}

[ ! -d ~/.vim/pack ] && 1>&2 echo "pack directory not found. Consider running /opt/ConfigShell/install.sh" && exit 1
cdOrExit ~/.vim/pack 


# Nice packages can be found on the following site:
# - https://vimawesome.com/
#

# Install packages
#
# 1. ALE

if [ -d ale ] ; then
   if [ -d ale/start/ale ] ; then 
      cdOrExit ale/start/ale 
      echo ale found, updating it.
      git pull
      cdOrExit -
   else
      echo ale existing but no default installation, not touching it.
   fi
else
   echo ale not found, installing it.
   mkCdOrExit ale/start && git clone https://github.com/dense-analysis/ale.git
   cdOrExit -
fi

# 2. Copilot

if [ -d copilot ] ; then
   if [ -d copilot/start/copilot ] ; then 
      cdOrExit copilot/start/copilot 
      echo copilot found, updating it.
      git pull
      cdOrExit -
   else
      echo copilot existing but no default installation, not touching it.
   fi
else
   echo copilot not found, installing it.
   mkCdOrExit copilot/start && git clone https://github.com/github/copilot.vim.git
   cdOrExit -
fi

# 3. vim-go

if [ -d go ] ; then
   if [ -d go/start/vim-go ] ; then 
      cdOrExit go/start/vim-go 
      echo copilot found, updating it.
      git pull
      cdOrExit -
   else
      echo vim-go existing but no default installation, not touching it.
   fi
else
   echo vim-go not found, installing it.
   mkCdOrExit go/start/vim-go && git clone https://github.com/fatih/vim-go.git
   cdOrExit -
fi

# 4. surround

if [ -d parentheses ] ; then
   if [ -d parentheses/start/surround ] ; then 
      cdOrExit parentheses/start/surround 
      echo surround found, updating it.
      git pull
      cdOrExit -
   else
      echo surround existing but no default installation, not touching it.
   fi
else
   echo surround not found, installing it.
   mkCdOrExit parentheses/start/surround && git clone https://tpope.io/vim/surround.git
   cdOrExit -
fi

# 5. vim-airline status line

if [ -d statusline ] ; then
   if [ -d statusline/start/vim-airline ] ; then 
      cdOrExit statusline/start/vim-airline 
      echo vim-airline found, updating it.
      git pull
      cdOrExit -
   else
      echo vim-airline existing but no default installation, not touching it.
   fi
else
   echo vim-airline not found, installing it.
   mkCdOrExit statusline/start/vim-airline && git clone https://github.com/vim-airline/vim-airline
   cdOrExit -
fi

# 6. versionCtrl

if [ -d versionCtrl ] ; then
   if [ -d versionCtrl/start/vim-fugitive ] ; then 
      cdOrExit versionCtrl/start/vim-fugitive 
      echo vim-fugitive found, updating it.
      git pull
      cdOrExit -
   else
      echo vim-fugitive existing but no default installation, not touching it.
   fi
else
   echo vim-fugitive not found, installing it.
   mkCdOrExit versionCtrl/start && git clone https://tpope.io/vim/fugitive.git
   cdOrExit -
fi

# 7. vim-markdown
# This is a markdown syntax highlighter

if [ -d markdown ] ; then
   if [ -d markdown/start/vim-markdown ] ; then 
      cdOrExit markdown/start/vim-markdown 
      echo vim-markdown found, updating it.
      git pull
      cdOrExit -
   else
      echo vim-markdown existing but no default installation, not touching it.
   fi
else
   echo vim-markdown not found, installing it.
   mkCdOrExit markdown/start && git clone https://github.com/plasticboy/vim-markdown.git
   cdOrExit -
fi

# EOF
